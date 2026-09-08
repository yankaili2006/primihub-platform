package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataModelArtifactReq;
import com.primihub.biz.service.data.DataModelArtifactService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 模型产物登记接口（外部已训模型：权重/配置/规则包等）
 */
@Api(value = "模型产物登记接口", tags = "模型产物登记接口")
@RequestMapping("artifact")
@RestController
@Slf4j
public class ModelArtifactController {

    @Autowired
    private DataModelArtifactService dataModelArtifactService;

    /**
     * 登记或编辑模型产物
     */
    @ApiOperation(value = "登记或编辑模型产物")
    @PostMapping("saveModelArtifact")
    public BaseResultEntity saveModelArtifact(@RequestBody DataModelArtifactReq req,
                                              @RequestHeader(value = "userId", required = false, defaultValue = "0") Long userId) {
        if (req.getArtifactId() != null && req.getArtifactId() != 0L) {
            return dataModelArtifactService.editModelArtifact(req);
        }
        if (StringUtils.isBlank(req.getModelName())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "modelName");
        }
        if (StringUtils.isBlank(req.getModelKind())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "modelKind");
        }
        return dataModelArtifactService.saveModelArtifact(req, userId);
    }

    /**
     * 模型产物分页列表（按名称/类别/框架/机构过滤）
     */
    @ApiOperation(value = "模型产物分页列表")
    @GetMapping("getModelArtifactList")
    public BaseResultEntity getModelArtifactList(DataModelArtifactReq req) {
        return dataModelArtifactService.getModelArtifactList(req);
    }

    /**
     * 查询单个模型产物
     */
    @ApiOperation(value = "查询单个模型产物")
    @GetMapping("getModelArtifact")
    public BaseResultEntity getModelArtifact(Long artifactId) {
        if (artifactId == null || artifactId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "artifactId");
        }
        return dataModelArtifactService.getModelArtifact(artifactId);
    }

    /**
     * 删除模型产物（软删）
     */
    @ApiOperation(value = "删除模型产物")
    @GetMapping("delModelArtifact")
    public BaseResultEntity delModelArtifact(Long artifactId) {
        if (artifactId == null || artifactId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "artifactId");
        }
        return dataModelArtifactService.deleteModelArtifact(artifactId);
    }
}
