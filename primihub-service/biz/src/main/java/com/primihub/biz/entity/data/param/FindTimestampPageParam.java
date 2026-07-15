package com.primihub.biz.entity.data.param;

import lombok.Data;

/**
 * 时间戳查询参数
 */
@Data
public class FindTimestampPageParam {
    private String title;
    private Integer applyStatus;
    private Integer pageNum = 1;
    private Integer pageSize = 10;
}