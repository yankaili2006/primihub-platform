package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.DataDifference;
import com.primihub.biz.entity.data.po.DataDifferenceTask;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface DataDifferenceRepository {

    List<Map<String, Object>> selectTaskPage(Map<String, Object> params);

    Long selectTaskPageCount(Map<String, Object> params);

    DataDifferenceTask selectTaskByTaskId(String taskId);

    DataDifferenceTask selectTaskById(Long id);

    DataDifference selectById(Long id);
}
