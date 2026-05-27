package com.primihub.biz.util;

import com.primihub.biz.entity.data.req.DataComponentReq;
import com.primihub.biz.entity.data.req.DataComponentRelationReq;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ModelComponentDagTest {

    private static DataComponentRelationReq edge(String code) {
        DataComponentRelationReq r = new DataComponentRelationReq();
        r.setComponentCode(code);
        return r;
    }

    private static DataComponentReq node(String code, int x, List<String> inputs, List<String> outputs) {
        DataComponentReq c = new DataComponentReq();
        c.setComponentCode(code);
        c.setCoordinateX(x);
        c.setCoordinateY(0);
        List<DataComponentRelationReq> in = new ArrayList<>();
        for (String i : inputs) in.add(edge(i));
        List<DataComponentRelationReq> out = new ArrayList<>();
        for (String o : outputs) out.add(edge(o));
        c.setInput(in);
        c.setOutput(out);
        return c;
    }

    private static int idx(List<String> order, String code) {
        return order.indexOf(code);
    }

    /** 1. 线性链：与旧递归实现顺序一致（向后兼容）。 */
    @Test
    void linearChainKeepsOrder() {
        List<DataComponentReq> comps = Arrays.asList(
                node("start", 0, Arrays.asList(), Arrays.asList("A")),
                node("A", 1, Arrays.asList("start"), Arrays.asList("B")),
                node("B", 2, Arrays.asList("A"), Arrays.asList("C")),
                node("C", 3, Arrays.asList("B"), Arrays.asList())
        );
        assertEquals(Arrays.asList("start", "A", "B", "C"),
                ModelComponentDag.build(comps).topoSort());
    }

    /** 2. 菱形：去重 + 拓扑约束（A 最前、D 最后、各出现一次）。 */
    @Test
    void diamondDedupAndOrder() {
        List<DataComponentReq> comps = Arrays.asList(
                node("A", 0, Arrays.asList(), Arrays.asList("B", "C")),
                node("B", 1, Arrays.asList("A"), Arrays.asList("D")),
                node("C", 2, Arrays.asList("A"), Arrays.asList("D")),
                node("D", 3, Arrays.asList("B", "C"), Arrays.asList())
        );
        List<String> order = ModelComponentDag.build(comps).topoSort();
        assertEquals(4, order.size());
        assertEquals("A", order.get(0));
        assertEquals("D", order.get(3));
        assertTrue(idx(order, "B") < idx(order, "D"));
        assertTrue(idx(order, "C") < idx(order, "D"));
    }

    /** 3. 多根：两个无输入的根都排在汇聚节点之前（旧实现只取首根，会丢一个）。 */
    @Test
    void multiRootBothPrecedeMerge() {
        List<DataComponentReq> comps = Arrays.asList(
                node("r1", 0, Arrays.asList(), Arrays.asList("m")),
                node("r2", 1, Arrays.asList(), Arrays.asList("m")),
                node("m", 2, Arrays.asList("r1", "r2"), Arrays.asList("t")),
                node("t", 3, Arrays.asList("m"), Arrays.asList())
        );
        List<String> order = ModelComponentDag.build(comps).topoSort();
        assertEquals(4, order.size());
        assertTrue(idx(order, "r1") < idx(order, "m"));
        assertTrue(idx(order, "r2") < idx(order, "m"));
        assertTrue(idx(order, "m") < idx(order, "t"));
    }

    /** 4. 扇入：汇聚节点必须等所有前驱（旧实现首前驱到达即排入，先于其他前驱）。 */
    @Test
    void fanInWaitsAllPredecessors() {
        List<DataComponentReq> comps = Arrays.asList(
                node("d1", 0, Arrays.asList(), Arrays.asList("align")),
                node("d2", 1, Arrays.asList(), Arrays.asList("align")),
                node("align", 2, Arrays.asList("d1", "d2"), Arrays.asList("model")),
                node("model", 3, Arrays.asList("align"), Arrays.asList())
        );
        List<String> order = ModelComponentDag.build(comps).topoSort();
        assertTrue(idx(order, "d1") < idx(order, "align"));
        assertTrue(idx(order, "d2") < idx(order, "align"));
        assertTrue(idx(order, "align") < idx(order, "model"));
    }

    /** 5. 环：必须抛异常而非旧实现的栈溢出。 */
    @Test
    void cycleThrows() {
        List<DataComponentReq> comps = Arrays.asList(
                node("A", 0, Arrays.asList("B"), Arrays.asList("B")),
                node("B", 1, Arrays.asList("A"), Arrays.asList("A"))
        );
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> ModelComponentDag.build(comps).topoSort());
        assertTrue(ex.getMessage().contains("环"));
    }

    /** 6. 悬挂边：出边指向不存在组件，构建期即报错（旧实现 NPE）。 */
    @Test
    void danglingEdgeThrows() {
        List<DataComponentReq> comps = Arrays.asList(
                node("A", 0, Arrays.asList(), Arrays.asList("ghost"))
        );
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> ModelComponentDag.build(comps));
        assertTrue(ex.getMessage().contains("ghost"));
    }
}
