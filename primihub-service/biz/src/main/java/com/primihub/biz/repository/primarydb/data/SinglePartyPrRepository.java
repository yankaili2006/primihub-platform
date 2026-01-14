package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.SingleParty;
import com.primihub.biz.entity.data.po.SinglePartyTask;
import org.springframework.stereotype.Repository;

@Repository
public interface SinglePartyPrRepository {

    int saveSingleParty(SingleParty singleParty);

    int saveSinglePartyTask(SinglePartyTask task);

    int updateSingleParty(SingleParty singleParty);

    int updateSinglePartyTask(SinglePartyTask task);

    int deleteTask(String taskId);

    int cancelTask(String taskId);
}
