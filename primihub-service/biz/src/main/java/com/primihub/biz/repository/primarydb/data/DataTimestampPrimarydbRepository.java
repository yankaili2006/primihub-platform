package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataTimestamp;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DataTimestampPrimarydbRepository {
    void insertTimestamp(DataTimestamp timestamp);
    void updateTimestamp(DataTimestamp timestamp);
    void updateTimestampStatus(@Param("id") Long id, @Param("applyStatus") Integer applyStatus,
                                @Param("timestampValue") String timestampValue,
                                @Param("certNumber") String certNumber);
    void deleteTimestamp(@Param("id") Long id);
}