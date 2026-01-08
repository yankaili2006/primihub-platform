package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.SysOperationLog;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 系统操作日志主库Repository（写操作）
 */
@Repository
public interface SysOperationLogPrimarydbRepository {

    /**
     * 插入操作日志记录
     *
     * @param log 操作日志实体
     * @return 影响行数
     */
    int insertOperationLog(SysOperationLog log);

    /**
     * 删除操作日志记录（软删除）
     *
     * @param logId 日志ID
     * @return 影响行数
     */
    int deleteOperationLog(@Param("logId") Long logId);

    /**
     * 批量删除操作日志记录（软删除）
     *
     * @param logIds 日志ID列表
     * @return 影响行数
     */
    int batchDeleteOperationLog(@Param("logIds") List<Long> logIds);
}
