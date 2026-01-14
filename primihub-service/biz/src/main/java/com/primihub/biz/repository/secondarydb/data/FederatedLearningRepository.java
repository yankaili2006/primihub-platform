package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.FederatedLearning;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface FederatedLearningRepository {

    List<Map<String, Object>> selectTaskPage(Map<String, Object> params);

    Long selectTaskPageCount(Map<String, Object> params);

    FederatedLearningTask selectTaskByTaskId(String taskId);

    FederatedLearning selectById(Long id);

    List<Map<String, Object>> selectModelList(Map<String, Object> params);

    Long selectModelListCount(Map<String, Object> params);
}
