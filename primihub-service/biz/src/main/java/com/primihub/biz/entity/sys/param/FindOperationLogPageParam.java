package com.primihub.biz.entity.sys.param;

import lombok.Data;

/**
 * 查询操作日志分页参数
 */
@Data
public class FindOperationLogPageParam {

    /**
     * 操作用户ID（可选）
     */
    private Long userId;

    /**
     * 操作用户名模糊搜索（可选）
     */
    private String userName;

    /**
     * 操作类型筛选（可选）：1=新增，2=修改，3=删除，4=登录，5=登出
     */
    private Integer operationType;

    /**
     * 操作模块筛选（可选）
     */
    private String operationModule;

    /**
     * 开始时间（可选）
     */
    private String startTime;

    /**
     * 结束时间（可选）
     */
    private String endTime;

    /**
     * 执行状态筛选（可选）：0=失败，1=成功
     */
    private Integer isSuccess;

    /**
     * 页码（默认1）
     */
    private Integer pageNo = 1;

    /**
     * 每页大小（默认10）
     */
    private Integer pageSize = 10;
}
