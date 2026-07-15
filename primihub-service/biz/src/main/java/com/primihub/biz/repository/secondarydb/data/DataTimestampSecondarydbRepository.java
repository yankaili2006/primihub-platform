package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.DataTimestamp;
import com.primihub.biz.entity.data.param.FindTimestampPageParam;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DataTimestampSecondarydbRepository {
    List<DataTimestamp> selectTimestampPage(FindTimestampPageParam param);
    Integer selectTimestampCount(FindTimestampPageParam param);
    DataTimestamp selectTimestampById(Long id);
    DataTimestamp selectTimestampByApplyId(String applyId);
}