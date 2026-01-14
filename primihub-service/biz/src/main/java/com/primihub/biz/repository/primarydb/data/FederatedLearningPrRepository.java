package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.FederatedLearning;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import org.springframework.stereotype.Repository;

@Repository
public interface FederatedLearningPrRepository {

    int saveFederatedLearning(FederatedLearning federatedLearning);

    int saveFederatedLearningTask(FederatedLearningTask task);

    int updateFederatedLearning(FederatedLearning federatedLearning);

    int updateFederatedLearningTask(FederatedLearningTask task);

    int deleteTask(String taskId);

    int cancelTask(String taskId);
}
