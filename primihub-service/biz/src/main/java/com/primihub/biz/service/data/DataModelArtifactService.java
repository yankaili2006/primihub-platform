package com.primihub.biz.service.data;

import com.primihub.biz.config.base.OrganConfiguration;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.data.po.DataModelArtifact;
import com.primihub.biz.entity.data.req.DataModelArtifactReq;
import com.primihub.biz.entity.data.vo.DataModelArtifactVo;
import com.primihub.biz.entity.sys.po.SysFile;
import com.primihub.biz.entity.sys.po.SysUser;
import com.primihub.biz.repository.primarydb.data.DataModelArtifactPrRepository;
import com.primihub.biz.repository.secondarydb.data.DataModelArtifactRepository;
import com.primihub.biz.repository.secondarydb.sys.SysFileSecondarydbRepository;
import com.primihub.biz.service.sys.SysUserService;
import com.primihub.biz.util.FileUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 外部模型产物登记服务
 * 与 data_model（联邦训练DAG模板）/data_reasoning（推理任务）语义独立
 */
@Service
@Slf4j
public class DataModelArtifactService {

    @Autowired
    private DataModelArtifactPrRepository dataModelArtifactPrRepository;
    @Autowired
    private DataModelArtifactRepository dataModelArtifactRepository;
    @Autowired
    private SysFileSecondarydbRepository sysFileSecondarydbRepository;
    @Autowired
    private SysUserService sysUserService;
    @Autowired
    private OrganConfiguration organConfiguration;

    public BaseResultEntity saveModelArtifact(DataModelArtifactReq req, Long userId) {
        DataModelArtifact artifact = new DataModelArtifact();
        artifact.setModelName(req.getModelName());
        artifact.setModelKind(req.getModelKind());
        artifact.setFramework(req.getFramework());
        artifact.setFormat(req.getFormat());
        artifact.setVersion(req.getVersion());
        artifact.setChecksum(req.getChecksum());
        artifact.setMetadata(req.getMetadata());
        artifact.setUserId(userId);
        artifact.setOrganId(organConfiguration.getSysLocalOrganId());
        if (req.getFileId() != null && req.getFileId() != 0L) {
            SysFile sysFile = sysFileSecondarydbRepository.selectSysFileByFileId(req.getFileId());
            if (sysFile == null) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "fileId");
            }
            artifact.setFileId(sysFile.getFileId());
            artifact.setUrl(sysFile.getFileUrl());
            if (StringUtils.isBlank(artifact.getChecksum())) {
                try {
                    File file = new File(sysFile.getFileUrl());
                    if (file.exists()) {
                        artifact.setChecksum(FileUtil.md5HashCode(file));
                    }
                } catch (Exception e) {
                    log.info("artifact file:{} md5 error:{}", sysFile.getFileUrl(), e.getMessage());
                }
            }
        }
        try {
            dataModelArtifactPrRepository.saveModelArtifact(artifact);
        } catch (Exception e) {
            log.info("save DataModelArtifact Exception:{}", e.getMessage());
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL);
        }
        Map<String, Object> map = new HashMap<>();
        map.put("artifactId", artifact.getArtifactId());
        map.put("modelName", artifact.getModelName());
        return BaseResultEntity.success(map);
    }

    public BaseResultEntity editModelArtifact(DataModelArtifactReq req) {
        DataModelArtifact artifact = dataModelArtifactRepository.queryModelArtifactById(req.getArtifactId());
        if (artifact == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "找不到模型产物信息");
        }
        DataModelArtifact update = new DataModelArtifact();
        update.setArtifactId(req.getArtifactId());
        update.setModelName(req.getModelName());
        update.setModelKind(req.getModelKind());
        update.setFramework(req.getFramework());
        update.setFormat(req.getFormat());
        update.setVersion(req.getVersion());
        update.setChecksum(req.getChecksum());
        update.setMetadata(req.getMetadata());
        if (req.getFileId() != null && req.getFileId() != 0L) {
            SysFile sysFile = sysFileSecondarydbRepository.selectSysFileByFileId(req.getFileId());
            if (sysFile == null) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "fileId");
            }
            update.setFileId(sysFile.getFileId());
            update.setUrl(sysFile.getFileUrl());
        }
        dataModelArtifactPrRepository.updateModelArtifact(update);
        return BaseResultEntity.success();
    }

    public BaseResultEntity getModelArtifactList(DataModelArtifactReq req) {
        Map<String, Object> paramMap = new HashMap<>();
        paramMap.put("offset", req.getOffset());
        paramMap.put("pageSize", req.getPageSize());
        paramMap.put("modelName", req.getModelName());
        paramMap.put("modelKind", req.getModelKind());
        paramMap.put("framework", req.getFramework());
        paramMap.put("organId", req.getOrganId());
        List<DataModelArtifact> artifacts = dataModelArtifactRepository.queryModelArtifactList(paramMap);
        if (artifacts.isEmpty()) {
            return BaseResultEntity.success(new PageDataEntity(0, req.getPageSize(), req.getPageNo(), new ArrayList()));
        }
        Integer count = dataModelArtifactRepository.queryModelArtifactCount(paramMap);
        Set<Long> userIds = artifacts.stream().map(DataModelArtifact::getUserId).collect(Collectors.toSet());
        Map<Long, SysUser> sysUserMap = sysUserService.getSysUserMap(new HashSet<>(userIds));
        List<DataModelArtifactVo> voList = artifacts.stream().map(po -> {
            DataModelArtifactVo vo = poConvertVo(po);
            SysUser sysUser = sysUserMap.get(po.getUserId());
            vo.setUserName(sysUser == null ? "" : sysUser.getUserName());
            return vo;
        }).collect(Collectors.toList());
        return BaseResultEntity.success(new PageDataEntity(count, req.getPageSize(), req.getPageNo(), voList));
    }

    public BaseResultEntity getModelArtifact(Long artifactId) {
        DataModelArtifact artifact = dataModelArtifactRepository.queryModelArtifactById(artifactId);
        if (artifact == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL);
        }
        DataModelArtifactVo vo = poConvertVo(artifact);
        SysUser sysUser = sysUserService.getSysUserById(artifact.getUserId());
        vo.setUserName(sysUser == null ? "" : sysUser.getUserName());
        return BaseResultEntity.success(vo);
    }

    public BaseResultEntity deleteModelArtifact(Long artifactId) {
        DataModelArtifact artifact = dataModelArtifactRepository.queryModelArtifactById(artifactId);
        if (artifact == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "找不到模型产物信息");
        }
        dataModelArtifactPrRepository.deleteModelArtifact(artifactId);
        return BaseResultEntity.success();
    }

    private DataModelArtifactVo poConvertVo(DataModelArtifact po) {
        DataModelArtifactVo vo = new DataModelArtifactVo();
        vo.setArtifactId(po.getArtifactId());
        vo.setModelName(po.getModelName());
        vo.setModelKind(po.getModelKind());
        vo.setFramework(po.getFramework());
        vo.setFormat(po.getFormat());
        vo.setVersion(po.getVersion());
        vo.setFileId(po.getFileId());
        vo.setUrl(po.getUrl());
        vo.setObjectKey(po.getObjectKey());
        vo.setChecksum(po.getChecksum());
        vo.setMetadata(po.getMetadata());
        vo.setOrganId(po.getOrganId());
        vo.setUserId(po.getUserId());
        vo.setCreateDate(po.getCreateDate());
        return vo;
    }
}
