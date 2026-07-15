package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.SysLogType;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface SysLogTypePrimarydbRepository {
    void insertLogType(SysLogType logType);
    void updateLogType(SysLogType logType);
    void deleteLogType(@Param("id") Long id);
}