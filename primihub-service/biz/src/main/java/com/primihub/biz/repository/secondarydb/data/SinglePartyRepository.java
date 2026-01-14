package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.SingleParty;
import com.primihub.biz.entity.data.po.SinglePartyTask;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface SinglePartyRepository {

    List<Map<String, Object>> selectTaskPage(Map<String, Object> params);

    Long selectTaskPageCount(Map<String, Object> params);

    SinglePartyTask selectTaskByTaskId(String taskId);

    SingleParty selectById(Long id);
}
