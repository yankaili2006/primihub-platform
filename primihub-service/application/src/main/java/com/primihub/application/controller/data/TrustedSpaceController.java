package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataResourceReq;
import com.primihub.biz.entity.data.req.TrustedSpaceReq;
import com.primihub.biz.entity.data.req.TrustedSpaceResourceReq;
import com.primihub.biz.service.data.DataTrustedSpaceService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 可信空间管理。经网关 data-url-proxy（/data/** StripPrefix=1）暴露为 /data/trustedSpace/*。
 * 鉴权路径（sys_auth.auth_url）：/trustedSpace/page|detail|save|update|delete|assignResources|removeResources。
 */
@Api(tags = "可信空间管理")
@RestController
@RequestMapping("trustedSpace")
public class TrustedSpaceController {

    @Autowired
    private DataTrustedSpaceService trustedSpaceService;

    @ApiOperation("分页查询可信空间")
    @GetMapping("page")
    public BaseResultEntity page(TrustedSpaceReq req) {
        if (req == null) {
            req = new TrustedSpaceReq();
        }
        if (req.getPageSize() == null || req.getPageSize() <= 0 || req.getPageNo() == null || req.getPageNo() <= 0) {
            return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "pageNo/pageSize");
        }
        return trustedSpaceService.page(req);
    }

    @ApiOperation("全部启用的可信空间（下拉用）")
    @GetMapping("listAll")
    public BaseResultEntity listAll() {
        return trustedSpaceService.listAll();
    }

    @ApiOperation("可信空间详情")
    @GetMapping("detail")
    public BaseResultEntity detail(@RequestParam(required = false) Long spaceId) {
        if (spaceId == null || spaceId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        return trustedSpaceService.detail(spaceId);
    }

    @ApiOperation("新建可信空间")
    @PostMapping("save")
    public BaseResultEntity save(@RequestBody(required = false) TrustedSpaceReq req,
                                 @RequestHeader(value = "userId", required = false, defaultValue = "0") Long userId) {
        if (req == null || req.getSpaceName() == null || "".equals(req.getSpaceName().trim())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceName");
        }
        return trustedSpaceService.save(req, userId);
    }

    @ApiOperation("编辑可信空间")
    @PostMapping("update")
    public BaseResultEntity update(@RequestBody(required = false) TrustedSpaceReq req,
                                   @RequestHeader(value = "userId", required = false, defaultValue = "0") Long userId) {
        if (req == null || req.getSpaceId() == null || req.getSpaceId() == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        return trustedSpaceService.update(req, userId);
    }

    @ApiOperation("删除可信空间（其资源回到缺省空间）")
    @PostMapping("delete")
    public BaseResultEntity delete(@RequestParam(required = false) Long spaceId) {
        if (spaceId == null || spaceId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        return trustedSpaceService.delete(spaceId);
    }

    @ApiOperation("把资源划入可信空间")
    @PostMapping("assignResources")
    public BaseResultEntity assignResources(@RequestBody(required = false) TrustedSpaceResourceReq req) {
        if (req == null || req.getSpaceId() == null || req.getSpaceId() == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        if (req.getResourceIds() == null || req.getResourceIds().isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resourceIds");
        }
        return trustedSpaceService.assignResources(req);
    }

    @ApiOperation("把资源移出可信空间（回到缺省空间）")
    @PostMapping("removeResources")
    public BaseResultEntity removeResources(@RequestBody(required = false) TrustedSpaceResourceReq req) {
        if (req == null || req.getSpaceId() == null || req.getSpaceId() == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        if (req.getResourceIds() == null || req.getResourceIds().isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resourceIds");
        }
        return trustedSpaceService.removeResources(req);
    }

    @ApiOperation("空间内资源分页")
    @GetMapping("resources")
    public BaseResultEntity resources(@RequestParam(required = false) Long spaceId,
                                      DataResourceReq req,
                                      @RequestHeader(value = "userId", required = false, defaultValue = "0") Long userId) {
        if (spaceId == null || spaceId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        return trustedSpaceService.resourcePage(spaceId, req, userId);
    }
}
