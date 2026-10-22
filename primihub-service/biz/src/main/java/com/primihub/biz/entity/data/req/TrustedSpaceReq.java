package com.primihub.biz.entity.data.req;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

/**
 * 可信空间 查询 / 保存 / 编辑 入参。查询走 GET 绑定（分页字段继承 PageReq），保存走 JSON。
 */
@Data
@ApiModel("可信空间入参")
public class TrustedSpaceReq extends PageReq {
    @ApiModelProperty("空间id（编辑时必填）")
    private Long spaceId;
    @ApiModelProperty("空间编码，^[A-Za-z0-9_-]{1,64}$；新建留空则自动生成")
    private String spaceCode;
    @ApiModelProperty("空间名称（查询时模糊匹配）")
    private String spaceName;
    @ApiModelProperty("描述")
    private String spaceDesc;
    @ApiModelProperty("1 启用 0 停用（查询时为过滤条件）")
    private Integer status;
    @ApiModelProperty("排序")
    private Integer sortIndex;
}
