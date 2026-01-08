package com.primihub.biz.repository.secondarydb.sys;

import com.primihub.biz.entity.sys.po.SysOperationLog;
import com.primihub.biz.entity.sys.param.FindOperationLogPageParam;
import com.primihub.biz.entity.sys.vo.SysOperationLogVO;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * 系统操作日志从库Repository（读操作）
 */
@Repository
public interface SysOperationLogSecondarydbRepository {

    /**
     * 根据ID查询操作日志
     *
     * @param logId 日志ID
     * @return 操作日志实体
     */
    SysOperationLog selectOperationLogById(@Param("logId") Long logId);

    /**
     * 分页查询操作日志列表
     *
     * @param param 查询参数
     * @return 操作日志VO列表
     */
    List<SysOperationLogVO> selectOperationLogPage(FindOperationLogPageParam param);

    /**
     * 查询操作日志总数
     *
     * @param param 查询参数
     * @return 总数
     */
    Long selectOperationLogCount(FindOperationLogPageParam param);

    /**
     * 查询操作日志统计信息
     *
     * @param param 查询参数
     * @return 统计信息
     */
    Map<String, Object> selectOperationLogStatistics(FindOperationLogPageParam param);
}
