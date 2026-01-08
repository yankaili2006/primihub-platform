package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.sys.param.FindOperationLogPageParam;
import com.primihub.biz.entity.sys.po.SysOperationLog;
import com.primihub.biz.entity.sys.vo.SysOperationLogVO;
import com.primihub.biz.repository.primarydb.sys.SysOperationLogPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysOperationLogSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 系统操作日志服务类
 */
@Slf4j
@Service
public class SysOperationLogService {

    @Autowired
    private SysOperationLogPrimarydbRepository primaryRepository;

    @Autowired
    private SysOperationLogSecondarydbRepository secondaryRepository;

    /**
     * 异步记录操作日志
     *
     * @param operationLog 操作日志实体
     */
    @Async
    public void recordOperationLog(SysOperationLog operationLog) {
        try {
            // 参数长度限制，避免存储过大数据
            if (operationLog.getRequestParams() != null &&
                operationLog.getRequestParams().length() > 5000) {
                operationLog.setRequestParams(
                    operationLog.getRequestParams().substring(0, 5000) + "...(truncated)");
            }
            if (operationLog.getExceptionMsg() != null &&
                operationLog.getExceptionMsg().length() > 2000) {
                operationLog.setExceptionMsg(
                    operationLog.getExceptionMsg().substring(0, 2000) + "...(truncated)");
            }

            // 异步插入日志
            primaryRepository.insertOperationLog(operationLog);
        } catch (Exception e) {
            // 日志记录失败不影响主业务，仅打印错误日志
            log.error("记录操作日志失败", e);
        }
    }

    /**
     * 分页查询操作日志
     *
     * @param param 查询参数
     * @return 分页数据
     */
    public BaseResultEntity findOperationLogPage(FindOperationLogPageParam param) {
        try {
            // 参数校验
            if (param.getPageNo() == null || param.getPageNo() < 1) {
                param.setPageNo(1);
            }
            if (param.getPageSize() == null || param.getPageSize() < 1) {
                param.setPageSize(10);
            }

            // 计算分页参数（LIMIT offset, size）
            int pageIndex = (param.getPageNo() - 1) * param.getPageSize();
            Integer originalPageNo = param.getPageNo(); // 保存原始pageNo用于返回
            param.setPageNo(pageIndex); // 临时设置为offset用于SQL

            // 查询数据
            List<SysOperationLogVO> list = secondaryRepository.selectOperationLogPage(param);
            Long total = secondaryRepository.selectOperationLogCount(param);

            // 恢复原始pageNo
            param.setPageNo(originalPageNo);

            // 构建分页结果（使用正确的构造函数）
            PageDataEntity<SysOperationLogVO> pageData = new PageDataEntity<>(
                total.intValue(),
                param.getPageSize(),
                param.getPageNo(),
                list
            );

            return BaseResultEntity.success(pageData);
        } catch (Exception e) {
            log.error("查询操作日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询操作日志失败");
        }
    }

    /**
     * 获取操作日志详情
     *
     * @param logId 日志ID
     * @return 日志详情
     */
    public BaseResultEntity getOperationLogDetail(Long logId) {
        try {
            if (logId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志ID不能为空");
            }

            SysOperationLog log = secondaryRepository.selectOperationLogById(logId);
            if (log == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "操作日志不存在");
            }

            return BaseResultEntity.success(log);
        } catch (Exception e) {
            log.error("获取操作日志详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取操作日志详情失败");
        }
    }

    /**
     * 删除操作日志
     *
     * @param logId  日志ID
     * @param userId 操作用户ID
     * @return 操作结果
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteOperationLog(Long logId, Long userId) {
        try {
            if (logId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志ID不能为空");
            }

            // 检查日志是否存在
            SysOperationLog log = secondaryRepository.selectOperationLogById(logId);
            if (log == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "操作日志不存在");
            }

            // 执行软删除
            int rows = primaryRepository.deleteOperationLog(logId);
            if (rows > 0) {
                return BaseResultEntity.success("删除成功");
            } else {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
            }
        } catch (Exception e) {
            log.error("删除操作日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除操作日志失败");
        }
    }

    /**
     * 获取操作日志统计信息
     *
     * @param param 查询参数
     * @return 统计信息
     */
    public BaseResultEntity getOperationLogStatistics(FindOperationLogPageParam param) {
        try {
            Map<String, Object> statistics = secondaryRepository.selectOperationLogStatistics(param);
            return BaseResultEntity.success(statistics);
        } catch (Exception e) {
            log.error("获取操作日志统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取操作日志统计失败");
        }
    }

    /**
     * 导出操作日志
     *
     * @param param    查询参数
     * @param response HTTP响应
     */
    public void exportOperationLog(FindOperationLogPageParam param, HttpServletResponse response) {
        try {
            // 设置不分页，查询所有匹配数据
            param.setPageNo(0);
            param.setPageSize(10000); // 最多导出10000条

            FindOperationLogPageParam queryParam = new FindOperationLogPageParam();
            queryParam.setUserId(param.getUserId());
            queryParam.setUserName(param.getUserName());
            queryParam.setOperationType(param.getOperationType());
            queryParam.setOperationModule(param.getOperationModule());
            queryParam.setIsSuccess(param.getIsSuccess());
            queryParam.setStartTime(param.getStartTime());
            queryParam.setEndTime(param.getEndTime());
            queryParam.setPageNo(0);
            queryParam.setPageSize(10000);

            List<SysOperationLogVO> list = secondaryRepository.selectOperationLogPage(queryParam);

            // 设置响应头
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition",
                "attachment;filename=operation_log_" + System.currentTimeMillis() + ".csv");

            // 写入CSV
            PrintWriter writer = response.getWriter();
            writer.println("日志ID,操作用户,操作类型,操作模块,操作描述,请求URL,响应状态,操作耗时(ms),IP地址,执行状态,操作时间");

            for (SysOperationLogVO vo : list) {
                writer.println(String.format("%d,%s,%s,%s,%s,%s,%s,%d,%s,%s,%s",
                    vo.getLogId(),
                    vo.getUserName() != null ? vo.getUserName() : "",
                    vo.getOperationTypeDesc() != null ? vo.getOperationTypeDesc() : "",
                    vo.getOperationModule() != null ? vo.getOperationModule() : "",
                    vo.getOperationDesc() != null ? vo.getOperationDesc() : "",
                    vo.getRequestUrl() != null ? vo.getRequestUrl() : "",
                    vo.getResponseCode() != null ? vo.getResponseCode() : "",
                    vo.getOperationTime() != null ? vo.getOperationTime() : 0,
                    vo.getIpAddress() != null ? vo.getIpAddress() : "",
                    vo.getIsSuccessDesc() != null ? vo.getIsSuccessDesc() : "",
                    vo.getCreatedTime() != null ? vo.getCreatedTime().toString() : ""
                ));
            }

            writer.flush();
        } catch (IOException e) {
            log.error("导出操作日志失败", e);
        }
    }
}
