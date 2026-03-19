import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import libsD3 from "c/libsD3";
import getRelationshipGraph from "@salesforce/apex/RelationshipsTreeGridController.getRelationshipGraph";
import { computeLayout } from "./tangledTreeLayout";

import REL_No_Relationships from "@salesforce/label/c.REL_No_Relationships";

// SLDS 2 design tokens
const BRAND_COLOR = "#0176d3";
const ROOT_BORDER_COLOR = "#032d60";
const TEXT_COLOR = "#181818";
const EDGE_LABEL_COLOR = "#444444";
const FONT_FAMILY = "'Salesforce Sans', Arial, sans-serif";
const STATUS_COLORS = {
    Current: "#2e844a",
    Former: "#939393",
};
const DEFAULT_EDGE_COLOR = BRAND_COLOR;

const NODE_HEIGHT = 32;
const NODE_PADDING_X = 16;
const NODE_CORNER_RADIUS = 6;
const CHAR_WIDTH = 7.5;

const DEPTH_OPTIONS = [
    { label: "1 level", value: "1" },
    { label: "2 levels", value: "2" },
    { label: "3 levels", value: "3" },
];

export default class RelationshipsTangledTree extends NavigationMixin(LightningElement) {
    @api recordId;
    @api depth = 2;
    @api isLightningOut = false;

    isLoading = true;
    hasError = false;
    errorMessage;
    hasData = false;
    hasNoRelationships = false;
    selectedNode = null;

    _depthValue = "2";
    _requestId = 0;
    _d3;
    _zoomBehavior;

    labels = {
        REL_No_Relationships,
    };

    async connectedCallback() {
        this._depthValue = String(this.depth);

        try {
            // Load D3 and fetch graph data in parallel
            const [, graphResult] = await Promise.all([
                libsD3.init(this),
                getRelationshipGraph({
                    contactId: this.recordId,
                    depth: parseInt(this.depth, 10),
                }),
            ]);
            this._d3 = libsD3.d3;
            this._handleGraphResult(graphResult);
        } catch (e) {
            const message = e.body ? e.body.message : e.message || "Failed to load visualization";
            this.hasError = true;
            this.errorMessage = message;
            this.isLoading = false;
        }
    }

    _handleGraphResult(result) {
        if (!result || !result.nodes || result.nodes.length <= 1) {
            this.hasNoRelationships = true;
            this.isLoading = false;
            return;
        }

        this.hasData = true;
        this.isLoading = false;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            this.renderGraph(result.nodes, result.links);
        });
    }

    // --- Depth menu ---

    get depthOptions() {
        return DEPTH_OPTIONS.map((opt) => ({
            ...opt,
            checked: opt.value === this._depthValue,
        }));
    }

    get depthLabel() {
        const opt = DEPTH_OPTIONS.find((o) => o.value === this._depthValue);
        return opt ? opt.label : "2 levels";
    }

    handleDepthSelect(event) {
        this._depthValue = event.detail.value;
        this.loadGraph(this.recordId, parseInt(this._depthValue, 10));
    }

    // --- Data loading ---

    async loadGraph(contactId, depth) {
        this.isLoading = true;
        this.hasError = false;
        this.hasNoRelationships = false;
        this.hasData = false;
        this.selectedNode = null;

        const requestId = ++this._requestId;

        try {
            const result = await getRelationshipGraph({
                contactId,
                depth: parseInt(depth, 10),
            });

            if (requestId !== this._requestId) {
                return;
            }

            this._handleGraphResult(result);
        } catch (error) {
            if (requestId !== this._requestId) {
                return;
            }
            const message = error.body ? error.body.message : error.message;
            this.hasError = true;
            this.errorMessage = message;
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent("accesserror", { detail: message }));
        }
    }

    // --- D3 rendering ---

    renderGraph(nodes, links) {
        const d3 = this._d3;
        const svgEl = this.template.querySelector("svg.tree-svg");
        if (!svgEl) {
            return;
        }

        // Estimate node widths from character count
        const nodeWidths = new Map();
        for (const n of nodes) {
            const label = n.label || "?";
            const w = Math.max(label.length * CHAR_WIDTH, 50) + NODE_PADDING_X * 2;
            nodeWidths.set(n.id, w);
        }

        const layout = computeLayout(nodes, links);
        const { positionedNodes, pathData, svgWidth, svgHeight } = layout;

        svgEl.setAttribute("width", svgWidth);
        svgEl.setAttribute("height", svgHeight);
        svgEl.setAttribute("viewBox", `0 0 ${svgWidth} ${svgHeight}`);

        const svg = d3.select(svgEl);
        svg.selectAll("*").remove();

        const g = svg.append("g").attr("class", "zoom-group");

        // Zoom: scroll-wheel only, no click-drag pan on background
        this._zoomBehavior = d3
            .zoom()
            .scaleExtent([0.3, 3])
            .filter((event) => event.type === "wheel" || event.type === "dblclick")
            .on("zoom", (event) => {
                g.attr("transform", event.transform);
            });
        svg.call(this._zoomBehavior);

        // Build edge lookup for drag updates
        const linkDataById = new Map();
        for (const ld of pathData) {
            if (!linkDataById.has(ld.source)) {
                linkDataById.set(ld.source, []);
            }
            linkDataById.get(ld.source).push(ld);
            if (!linkDataById.has(ld.target)) {
                linkDataById.set(ld.target, []);
            }
            linkDataById.get(ld.target).push(ld);
        }

        // --- Layer 1: Edges ---
        const edgePaths = g
            .selectAll("path.edge")
            .data(pathData)
            .enter()
            .append("path")
            .attr("class", "edge")
            .attr("d", (d) => d.path)
            .attr("fill", "none")
            .attr("stroke", (d) => STATUS_COLORS[d.status] || DEFAULT_EDGE_COLOR)
            .attr("stroke-width", 2)
            .attr("stroke-opacity", 0.5);

        // --- Layer 2: Edge labels (with white background, ON TOP of edges) ---
        const edgeLabelData = pathData.filter((d) => d.relationshipType);

        const edgeLabelGroups = g
            .selectAll("g.edge-label-group")
            .data(edgeLabelData)
            .enter()
            .append("g")
            .attr("class", "edge-label-group")
            .attr("transform", (d) => `translate(${d.labelX},${d.labelY})`);

        const edgeLabelBgs = edgeLabelGroups
            .append("rect")
            .attr("class", "edge-label-bg")
            .attr("fill", "rgba(255, 255, 255, 0.85)")
            .attr("rx", 3)
            .attr("ry", 3)
            .attr("pointer-events", "none");

        const edgeLabelTexts = edgeLabelGroups
            .append("text")
            .attr("class", "edge-label")
            .attr("text-anchor", "middle")
            .attr("dy", "0.35em")
            .attr("font-family", FONT_FAMILY)
            .attr("font-size", "0.75rem")
            .attr("fill", EDGE_LABEL_COLOR)
            .attr("pointer-events", "none")
            .text((d) => d.relationshipType);

        // Size background rects to fit rendered text
        edgeLabelTexts.each(function (_d, i) {
            const bbox = this.getBBox();
            const pad = 4;
            d3.select(edgeLabelBgs.nodes()[i])
                .attr("x", bbox.x - pad)
                .attr("y", bbox.y - pad)
                .attr("width", bbox.width + pad * 2)
                .attr("height", bbox.height + pad * 2);
        });

        // --- Layer 3: Nodes (on top of everything) ---
        const self = this;
        let dragMoved = false;
        const dragBehavior = d3
            .drag()
            .on("start", function () {
                dragMoved = false;
                d3.select(this).raise();
            })
            .on("drag", function (event, d) {
                dragMoved = true;
                d.x = event.x;
                d.y = event.y;
                d3.select(this).attr("transform", `translate(${d.x},${d.y})`);
                self._updateEdges(
                    d,
                    linkDataById,
                    positionedNodes,
                    edgePaths,
                    edgeLabelGroups,
                    edgeLabelTexts,
                    edgeLabelBgs,
                    d3
                );
            })
            .on("end", function (_event, d) {
                if (!dragMoved) {
                    self.handleNodeClick(d);
                }
            });

        const nodeGroups = g
            .selectAll("g.node")
            .data(positionedNodes)
            .enter()
            .append("g")
            .attr("class", "node")
            .attr("transform", (d) => `translate(${d.x},${d.y})`)
            .attr("role", "button")
            .attr("tabindex", "0")
            .attr("aria-label", (d) => `${d.label}${d.title ? ", " + d.title : ""}`)
            .attr("cursor", "pointer")
            .on("keydown", (event, d) => {
                if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    this.handleNodeClick(d);
                }
            })
            .call(dragBehavior);

        // Node background: white fill, colored border
        nodeGroups
            .append("rect")
            .attr("x", (d) => -(nodeWidths.get(d.id) || 80) / 2)
            .attr("y", -NODE_HEIGHT / 2)
            .attr("width", (d) => nodeWidths.get(d.id) || 80)
            .attr("height", NODE_HEIGHT)
            .attr("rx", NODE_CORNER_RADIUS)
            .attr("ry", NODE_CORNER_RADIUS)
            .attr("fill", "#ffffff")
            .attr("stroke", (d) => (d.isRoot ? ROOT_BORDER_COLOR : BRAND_COLOR))
            .attr("stroke-width", 2);

        // Node name text
        nodeGroups
            .append("text")
            .attr("text-anchor", "middle")
            .attr("dy", "0.35em")
            .attr("fill", TEXT_COLOR)
            .attr("font-family", FONT_FAMILY)
            .attr("font-size", "0.8125rem")
            .attr("font-weight", "700")
            .attr("pointer-events", "none")
            .text((d) => d.label);
    }

    _updateEdges(movedNode, linkDataById, allNodes, edgePaths, edgeLabelGroups, edgeLabelTexts, edgeLabelBgs, d3) {
        const nodeMap = new Map();
        for (const n of allNodes) {
            nodeMap.set(n.id, n);
        }

        const affectedLinks = linkDataById.get(movedNode.id) || [];
        for (const ld of affectedLinks) {
            const s = nodeMap.get(ld.source);
            const t = nodeMap.get(ld.target);
            if (!s || !t) {
                continue;
            }
            const dx = t.x - s.x;
            const cpOffset = Math.max(Math.abs(dx) * 0.4, 60);
            ld.path = `M ${s.x} ${s.y} C ${s.x + cpOffset} ${s.y}, ${t.x - cpOffset} ${t.y}, ${t.x} ${t.y}`;
            ld.labelX = (s.x + t.x) / 2;
            ld.labelY = (s.y + t.y) / 2;
        }

        edgePaths.attr("d", (d) => d.path);
        edgeLabelGroups.attr("transform", (d) => `translate(${d.labelX},${d.labelY})`);

        edgeLabelTexts.each(function (_d, i) {
            const bbox = this.getBBox();
            const pad = 4;
            d3.select(edgeLabelBgs.nodes()[i])
                .attr("x", bbox.x - pad)
                .attr("y", bbox.y - pad)
                .attr("width", bbox.width + pad * 2)
                .attr("height", bbox.height + pad * 2);
        });
    }

    // --- Detail panel ---

    handleNodeClick(nodeData) {
        this.selectedNode = { ...nodeData };
    }

    handleCloseDetail() {
        this.selectedNode = null;
    }

    handleViewRecord() {
        if (this.selectedNode) {
            if (this.isLightningOut) {
                window.open(`/lightning/r/Contact/${this.selectedNode.id}/view`, "_blank");
            } else {
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: this.selectedNode.id,
                        actionName: "view",
                    },
                });
            }
        }
    }

    handleRecenter() {
        if (this.selectedNode) {
            const newRootId = this.selectedNode.id;
            this.selectedNode = null;
            this.loadGraph(newRootId, parseInt(this._depthValue, 10));
        }
    }

    // --- Zoom controls ---

    handleZoomIn() {
        const svg = this._d3.select(this.template.querySelector("svg.tree-svg"));
        svg.transition().duration(300).call(this._zoomBehavior.scaleBy, 1.3);
    }

    handleZoomOut() {
        const svg = this._d3.select(this.template.querySelector("svg.tree-svg"));
        svg.transition().duration(300).call(this._zoomBehavior.scaleBy, 0.7);
    }

    handleZoomReset() {
        const svg = this._d3.select(this.template.querySelector("svg.tree-svg"));
        svg.transition().duration(300).call(this._zoomBehavior.transform, this._d3.zoomIdentity);
    }

    // --- Getters ---

    get depthValue() {
        return this._depthValue;
    }

    get showDetailPanel() {
        return this.selectedNode !== null;
    }

    get detailName() {
        return this.selectedNode ? this.selectedNode.label : "";
    }

    get detailTitle() {
        return this.selectedNode ? this.selectedNode.title : "";
    }

    get detailAccountName() {
        return this.selectedNode ? this.selectedNode.accountName : "";
    }

    get isSelectedNodeRoot() {
        return this.selectedNode ? this.selectedNode.isRoot : false;
    }
}
