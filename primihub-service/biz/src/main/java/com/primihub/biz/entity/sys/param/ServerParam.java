package com.primihub.biz.entity.sys.param;

import com.primihub.biz.entity.data.req.PageReq;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

@Data
@ApiModel("服务器查询参数")
public class ServerParam extends PageReq {
    @ApiModelProperty("服务器名称（模糊）")
    private String serverName;
    @ApiModelProperty("服务器类型: compute/storage/gateway/tee")
    private String serverType;
    @ApiModelProperty("服务器状态: 0离线 1在线 2维护")
    private Integer serverStatus;
}
