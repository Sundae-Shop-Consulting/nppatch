/*
    Copyright (c) 2021 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @description Controller class for RelationshipsTreeGrid LWC
*/
public with sharing class RelationshipsTreeGridController {

    @AuraEnabled(Cacheable=true)
    public static String getContactName(Id contactId) {
        return [SELECT Name FROM Contact WHERE Id = :contactId WITH SECURITY_ENFORCED LIMIT 1].Name;
    }

    @AuraEnabled(Cacheable=true)
    public static RelationshipsListView getInitialView(Id contactId) {
        RelationshipsService service = RelationshipsService.getInstance();

        List<RelationshipView> relationships = getRelationshipsWithAccessCheck(contactId);
        RelationshipsListView initialView = new RelationshipsListView(relationships);
        initialView.vfPageURL = service.getVFPageURL();
        initialView.labels = service.getListUILabels();
        initialView.showCreateRelationshipButton = service.canCreateRelationship();

        return initialView;
    }

    @AuraEnabled(Cacheable=true)
    public static List<RelationshipView> getRelationships(Id contactId) {
        return getRelationshipsWithAccessCheck(contactId);
    }

    private static List<RelationshipView> getRelationshipsWithAccessCheck(Id contactId) {
        RelationshipsService service = RelationshipsService.getInstance();
        if (service.hasListViewRequiredPerms()) {
            try {
                List<Relationship__c> relationships = service.getContactRelations(contactId);
                List<RelationshipView> listView = mapRelationshipListToViews(relationships);

                return listView;
            } catch (Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        } else {
            AuraHandledException ex = new AuraHandledException(Label.commonInsufficientPermissions);
            ex.setMessage(Label.commonInsufficientPermissions);
            throw ex;
        }
    }

    private static List<RelationshipView> mapRelationshipListToViews(List<Relationship__c> relationships) {
        List<RelationshipView> relations = new List<RelationshipView>();
        for (Relationship__c relationship : relationships) {
            relations.add(new RelationshipView(relationship));
        }
        return relations;
    }


    @AuraEnabled(Cacheable=true)
    public static RelationshipGraphView getRelationshipGraph(Id contactId, Integer depth) {
        RelationshipsService service = RelationshipsService.getInstance();
        if (!service.hasListViewRequiredPerms()) {
            AuraHandledException ex = new AuraHandledException(Label.commonInsufficientPermissions);
            ex.setMessage(Label.commonInsufficientPermissions);
            throw ex;
        }

        // Cap depth to prevent excessive SOQL usage
        Integer maxDepth = (depth == null || depth < 1) ? 2 : Math.min(depth, 3);

        try {
            // Fetch root contact
            Contact rootContact = [
                SELECT Name, Title, Account.Name
                FROM Contact
                WHERE Id = :contactId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            Map<Id, GraphNode> visitedNodes = new Map<Id, GraphNode>();
            List<GraphLink> links = new List<GraphLink>();
            Set<String> visitedEdges = new Set<String>();

            // Add root node
            GraphNode rootNode = new GraphNode();
            rootNode.id = contactId;
            rootNode.label = rootContact.Name;
            rootNode.title = rootContact.Title;
            rootNode.accountName = rootContact.Account?.Name;
            rootNode.depth = 0;
            rootNode.isRoot = true;
            visitedNodes.put(contactId, rootNode);

            // BFS traversal
            Set<Id> currentFrontier = new Set<Id>{ contactId };

            for (Integer level = 0; level < maxDepth && !currentFrontier.isEmpty(); level++) {
                List<Relationship__c> relationships = service.getRelationshipsForContacts(currentFrontier);
                Set<Id> nextFrontier = new Set<Id>();

                for (Relationship__c rel : relationships) {
                    Id relatedId = rel.RelatedContact__c;

                    // Deduplicate reciprocal edges using canonical pair key
                    String edgeKey;
                    if (rel.ReciprocalRelationship__c != null) {
                        Id minId = rel.Id < rel.ReciprocalRelationship__c ? rel.Id : rel.ReciprocalRelationship__c;
                        Id maxId = rel.Id < rel.ReciprocalRelationship__c ? rel.ReciprocalRelationship__c : rel.Id;
                        edgeKey = String.valueOf(minId) + '-' + String.valueOf(maxId);
                    } else {
                        edgeKey = String.valueOf(rel.Id);
                    }

                    if (!visitedEdges.contains(edgeKey)) {
                        visitedEdges.add(edgeKey);
                        GraphLink link = new GraphLink();
                        link.id = rel.Id;
                        link.source = rel.Contact__c;
                        link.target = relatedId;
                        link.relationshipType = rel.Type__c;
                        link.status = rel.Status__c;
                        links.add(link);
                    }

                    // Add node if not yet visited
                    if (!visitedNodes.containsKey(relatedId)) {
                        GraphNode node = new GraphNode();
                        node.id = relatedId;
                        node.label = rel.RelatedContact__r.Name;
                        node.title = rel.RelatedContact__r.Title;
                        node.accountName = rel.RelatedContact__r.Account?.Name;
                        node.depth = level + 1;
                        node.isRoot = false;
                        visitedNodes.put(relatedId, node);
                        nextFrontier.add(relatedId);
                    }
                }

                currentFrontier = nextFrontier;
            }

            RelationshipGraphView graphView = new RelationshipGraphView();
            graphView.nodes = visitedNodes.values();
            graphView.links = links;
            return graphView;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class RelationshipGraphView {
        @AuraEnabled public List<GraphNode> nodes;
        @AuraEnabled public List<GraphLink> links;
    }

    public class GraphNode {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public String title;
        @AuraEnabled public String accountName;
        @AuraEnabled public Integer depth;
        @AuraEnabled public Boolean isRoot;
    }

    public class GraphLink {
        @AuraEnabled public Id id;
        @AuraEnabled public Id source;
        @AuraEnabled public Id target;
        @AuraEnabled public String relationshipType;
        @AuraEnabled public String status;
    }

    public class RelationshipsListView {
        @AuraEnabled public String vfPageURL;
        @AuraEnabled public Map<String, String> labels;
        @AuraEnabled public List<RelationshipView> relations;
        @AuraEnabled public Boolean showCreateRelationshipButton;

        public RelationshipsListView(List<RelationshipView> relationshipViews) {
            this.relations = relationshipViews;
        }
    }

    public class RelationshipView {
        @AuraEnabled public Id relationshipId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String relationshipExplanation;
        @AuraEnabled public String title;
        @AuraEnabled public String accountName;

        public RelationshipView(Relationship__c relationship) {
            this.relationshipId = relationship.Id;
            this.contactId = relationship.RelatedContact__c;
            this.contactName = relationship.RelatedContact__r.Name;
            this.title = relationship.RelatedContact__r.Title;
            this.accountName = relationship.RelatedContact__r.Account.Name;
            this.relationshipExplanation = relationship.Relationship_Explanation__c;
        }
    }
}