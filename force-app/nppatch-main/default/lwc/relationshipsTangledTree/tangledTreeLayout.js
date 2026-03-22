/**
 * Pure layout algorithm for tangled tree / network graph.
 * No Salesforce or D3 dependencies — takes nodes[] and links[],
 * returns positioned nodes and SVG path data.
 */

const DEFAULTS = {
    columnWidth: 280,
    rowHeight: 80,
    padding: 80,
    nodeRadius: 24,
};

/**
 * @param {Array} nodes - [{id, label, depth, ...}]
 * @param {Array} links - [{source, target, ...}]
 * @param {Object} options - {columnWidth, rowHeight, padding}
 * @returns {{ positionedNodes: Array, pathData: Array, svgWidth: number, svgHeight: number }}
 */
export function computeLayout(nodes, links, options = {}) {
    const opts = { ...DEFAULTS, ...options };

    if (!nodes || nodes.length === 0) {
        return { positionedNodes: [], pathData: [], svgWidth: 0, svgHeight: 0 };
    }

    // Group nodes by depth
    const levels = new Map();
    for (const node of nodes) {
        const d = node.depth || 0;
        if (!levels.has(d)) {
            levels.set(d, []);
        }
        levels.get(d).push({ ...node });
    }

    // Build adjacency for barycenter ordering
    const adjacency = buildAdjacency(nodes, links);

    // Sort level keys
    const sortedDepths = Array.from(levels.keys()).sort((a, b) => a - b);

    // Barycenter heuristic: 4 forward+backward sweep passes
    for (let pass = 0; pass < 4; pass++) {
        // Forward sweep
        for (let i = 1; i < sortedDepths.length; i++) {
            orderByBarycenter(levels.get(sortedDepths[i]), levels.get(sortedDepths[i - 1]), adjacency);
        }
        // Backward sweep
        for (let i = sortedDepths.length - 2; i >= 0; i--) {
            orderByBarycenter(levels.get(sortedDepths[i]), levels.get(sortedDepths[i + 1]), adjacency);
        }
    }

    // Assign positions
    let maxRows = 0;
    for (const [depth, levelNodes] of levels) {
        if (levelNodes.length > maxRows) {
            maxRows = levelNodes.length;
        }
        for (let i = 0; i < levelNodes.length; i++) {
            levelNodes[i].x = opts.padding + depth * opts.columnWidth;
            levelNodes[i].y = opts.padding + i * opts.rowHeight + opts.rowHeight / 2;
        }
    }

    // Build node position lookup
    const nodeMap = new Map();
    for (const levelNodes of levels.values()) {
        for (const n of levelNodes) {
            nodeMap.set(n.id, n);
        }
    }

    // Generate bezier paths for links
    const pathData = links
        .map((link) => {
            const s = nodeMap.get(link.source);
            const t = nodeMap.get(link.target);
            if (!s || !t) {
                return null;
            }

            const dx = t.x - s.x;
            const cpOffset = Math.max(Math.abs(dx) * 0.4, 60);

            const path = `M ${s.x} ${s.y} C ${s.x + cpOffset} ${s.y}, ${t.x - cpOffset} ${t.y}, ${t.x} ${t.y}`;

            // Label midpoint (approximate center of cubic bezier)
            const labelX = (s.x + t.x) / 2;
            const labelY = (s.y + t.y) / 2;

            return {
                ...link,
                path,
                labelX,
                labelY,
                sourceX: s.x,
                sourceY: s.y,
                targetX: t.x,
                targetY: t.y,
            };
        })
        .filter(Boolean);

    const maxDepth = sortedDepths.length > 0 ? sortedDepths[sortedDepths.length - 1] : 0;
    const svgWidth = opts.padding * 2 + maxDepth * opts.columnWidth + opts.nodeRadius * 2;
    const svgHeight = opts.padding * 2 + (maxRows - 1) * opts.rowHeight + opts.nodeRadius * 2;

    const positionedNodes = Array.from(nodeMap.values());

    return { positionedNodes, pathData, svgWidth: Math.max(svgWidth, 400), svgHeight: Math.max(svgHeight, 300) };
}

function buildAdjacency(nodes, links) {
    const adj = new Map();
    for (const node of nodes) {
        adj.set(node.id, []);
    }
    for (const link of links) {
        if (adj.has(link.source)) {
            adj.get(link.source).push(link.target);
        }
        if (adj.has(link.target)) {
            adj.get(link.target).push(link.source);
        }
    }
    return adj;
}

function orderByBarycenter(currentLevel, referenceLevel, adjacency) {
    if (!currentLevel || !referenceLevel) {
        return;
    }

    // Build index map for reference level
    const refIndex = new Map();
    referenceLevel.forEach((node, idx) => {
        refIndex.set(node.id, idx);
    });

    // Compute barycenter for each node in current level
    const barycenters = currentLevel.map((node) => {
        const neighbors = (adjacency.get(node.id) || [])
            .filter((nId) => refIndex.has(nId))
            .map((nId) => refIndex.get(nId));

        const bc = neighbors.length > 0 ? neighbors.reduce((sum, idx) => sum + idx, 0) / neighbors.length : Infinity; // nodes with no connections keep their position

        return { node, bc };
    });

    // Sort by barycenter, stable for nodes with no connections
    barycenters.sort((a, b) => {
        if (a.bc === Infinity && b.bc === Infinity) {
            return 0;
        }
        return a.bc - b.bc;
    });

    // Re-assign in place
    for (let i = 0; i < currentLevel.length; i++) {
        currentLevel[i] = barycenters[i].node;
    }
}
