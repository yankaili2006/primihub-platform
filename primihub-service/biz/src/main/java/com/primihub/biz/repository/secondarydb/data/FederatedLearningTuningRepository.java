package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.FederatedLearningTuning;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface FederatedLearningTuningRepository {

    List<FederatedLearningTuning> selectByTuningId(String tuningId);

    String selectLatestTuningIdByBaseTaskId(String baseTaskId);

    FederatedLearningTuning selectTrialById(Long id);

    List<Map<String, Object>> selectRuns(Map<String, Object> params);

    Long selectRunsCount(Map<String, Object> params);
}
