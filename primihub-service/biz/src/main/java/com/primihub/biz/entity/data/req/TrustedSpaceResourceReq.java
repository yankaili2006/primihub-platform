package com.primihub.biz.entity.data.req;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import java.util.List;

/**
 * 资源划入 / 移出可信空间的入参。
 */
@Data
@ApiModel("可信空间资源归属入参")
public class TrustedSpaceResourceReq {
    @ApiModelProperty("空间id")
    private Long spaceId;
    @ApiModelProperty("资源id列表")
    private List<Long> resourceIds;
}
