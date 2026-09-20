package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.FederatedLearningTuning;
import org.springframework.stereotype.Repository;

@Repository
public interface FederatedLearningTuningPrRepository {

    int saveTrial(FederatedLearningTuning trial);

    int updateTrialMetrics(FederatedLearningTuning trial);

    int clearApplied(String tuningId);

    int markApplied(Long id);
}
