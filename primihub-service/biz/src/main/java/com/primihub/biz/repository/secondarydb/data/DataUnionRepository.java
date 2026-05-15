package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.DataUnion;
import com.primihub.biz.entity.data.po.DataUnionTask;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface DataUnionRepository {

    List<Map<String, Object>> selectTaskPage(Map<String, Object> params);

    Long selectTaskPageCount(Map<String, Object> params);

    DataUnionTask selectTaskByTaskId(String taskId);

    DataUnionTask selectTaskById(Long id);

    DataUnion selectById(Long id);
}
