package com.primihub.biz.util;

import com.primihub.biz.entity.data.req.DataComponentReq;
import com.primihub.biz.entity.data.req.DataComponentRelationReq;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.PriorityQueue;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 模型组件 DAG 排序器。
 *
 * 取代原 DataModelService 里只跟随首根 + 首出边的线性递归 sortComponent，
 * 用 Kahn 拓扑排序支持多根 / 扇入 / 扇出 / 菱形，并在构建期校验悬挂边、
 * 排序期检测环。对单根单链模型，输出顺序与旧实现一致（向后兼容）。
 *
 * 邻接关系以组件的 output 连线为权威方向（与旧 sortComponent 跟随 getOutput 一致）；
 * 入度由出边目标计数推导，避免 input/output 声明不一致带来的偏差。
 */
public class ModelComponentDag {

    private final Map<String, DataComponentReq> nodes;
    private final Map<String, List<String>> adj;
    private final Map<String, Integer> indegree;

    private ModelComponentDag(Map<String, DataComponentReq> nodes,
                              Map<String, List<String>> adj,
                              Map<String, Integer> indegree) {
        this.nodes = nodes;
        this.adj = adj;
        this.indegree = indegree;
    }

    /**
     * 构建并校验 DAG。输入非法时抛 IllegalArgumentException，message 可直接回前端。
     */
    public static ModelComponentDag build(List<DataComponentReq> components) {
        if (components == null || components.isEmpty()) {
            throw new IllegalArgumentException("未查询到模型组件信息");
        }
        Map<String, DataComponentReq> nodes = new LinkedHashMap<>();
        for (DataComponentReq c : components) {
            String code = c.getComponentCode();
            if (code == null || code.isEmpty()) {
                throw new IllegalArgumentException("组件缺少 componentCode");
            }
            if (nodes.put(code, c) != null) {
                throw new IllegalArgumentException("组件 code 重复:" + code);
            }
        }
        Map<String, List<String>> adj = new HashMap<>();
        Map<String, Integer> indegree = new HashMap<>();
        for (String code : nodes.keySet()) {
            adj.put(code, new ArrayList<>());
            indegree.put(code, 0);
        }
        for (DataComponentReq c : components) {
            List<DataComponentRelationReq> outs = c.getOutput();
            if (outs == null) {
                continue;
            }
            Set<String> seen = new HashSet<>();
            for (DataComponentRelationReq edge : outs) {
                String to = edge.getComponentCode();
                if (to == null || to.isEmpty()) {
                    continue;
                }
                if (!nodes.containsKey(to)) {
                    throw new IllegalArgumentException("组件连线指向不存在的组件:" + to);
                }
                if (seen.add(to)) {
                    adj.get(c.getComponentCode()).add(to);
                    indegree.put(to, indegree.get(to) + 1);
                }
            }
        }
        return new ModelComponentDag(nodes, adj, indegree);
    }

    /**
     * Kahn 拓扑排序，产出确定可复现的执行顺序。
     * 同时就绪的组件按 (coordinateX, coordinateY, componentCode) 稳定排序。
     * 存在环时抛 IllegalArgumentException 并列出受影响组件。
     */
    public List<String> topoSort() {
        Comparator<String> order = Comparator
                .comparingInt((String c) -> coord(nodes.get(c).getCoordinateX()))
                .thenComparingInt(c -> coord(nodes.get(c).getCoordinateY()))
                .thenComparing(Comparator.naturalOrder());
        Map<String, Integer> deg = new HashMap<>(indegree);
        PriorityQueue<String> ready = new PriorityQueue<>(order);
        for (Map.Entry<String, Integer> e : deg.entrySet()) {
            if (e.getValue() == 0) {
                ready.offer(e.getKey());
            }
        }
        List<String> result = new ArrayList<>(nodes.size());
        while (!ready.isEmpty()) {
            String n = ready.poll();
            result.add(n);
            List<String> outs = new ArrayList<>(adj.get(n));
            outs.sort(order);
            for (String m : outs) {
                int d = deg.get(m) - 1;
                deg.put(m, d);
                if (d == 0) {
                    ready.offer(m);
                }
            }
        }
        if (result.size() != nodes.size()) {
            List<String> stuck = nodes.keySet().stream()
                    .filter(c -> !result.contains(c))
                    .collect(Collectors.toList());
            throw new IllegalArgumentException("模型组件存在环依赖,无法排序:" + stuck);
        }
        return result;
    }

    public Map<String, DataComponentReq> getNodes() {
        return nodes;
    }

    private static int coord(Integer v) {
        return v == null ? Integer.MAX_VALUE : v;
    }
}
