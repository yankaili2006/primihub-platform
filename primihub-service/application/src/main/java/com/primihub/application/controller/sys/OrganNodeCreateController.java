package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.po.SysOrgan;
import com.primihub.biz.repository.primarydb.sys.SysOrganPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysOrganSecondarydbRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * D20 补丁：机构节点管理「创建机构」 POST /sys/organ/createOrganNode（原后端 404）。
 * 前端直接 CRUD 与后端联邦「申请-审批」模型不匹配；此处按 applyForJoinNode 的插入范式
 * 直接 insertSysOrgan（纯 DB 插入、无联网副作用），dedup 保护。独立类，不改现有 OrganController。
 */
@RestController
@RequestMapping("/organ")
public class OrganNodeCreateController {

    @Autowired
    private SysOrganPrimarydbRepository sysOrganPrimarydbRepository;
    @Autowired
    private SysOrganSecondarydbRepository sysOrganSecondarydbRepository;

    private static String s(Object o) { return o == null ? null : String.valueOf(o); }

    @PostMapping("/createOrganNode")
    public BaseResultEntity createOrganNode(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) body = new HashMap<String, Object>();
        String organId = s(body.get("organId"));
        String organName = s(body.get("organName"));
        Object gwo = body.get("gatewayAddress") != null ? body.get("gatewayAddress") : body.get("organGateway");
        String gateway = s(gwo);
        String publicKey = s(body.get("publicKey"));
        if (organId == null || organId.trim().isEmpty())
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "机构ID不能为空");
        if (organName == null || organName.trim().isEmpty())
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "机构名称不能为空");
        List existing = sysOrganSecondarydbRepository.selectOrganByOrganId(organId);
        if (existing != null && !existing.isEmpty())
            return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "机构已存在: " + organId);
        SysOrgan o = new SysOrgan();
        o.setApplyId(body.get("applyId") != null ? s(body.get("applyId")) : organId);
        o.setOrganId(organId);
        o.setOrganName(organName);
        o.setOrganGateway(gateway);
        o.setPublicKey(publicKey);
        o.setExamineState(Integer.valueOf(1));   // 已通过
        o.setNodeState(Integer.valueOf(0));
        o.setFusionState(Integer.valueOf(0));
        o.setPlatformState(Integer.valueOf(0));
        o.setEnable(Integer.valueOf(1));          // 启用
        o.setIsDel(Integer.valueOf(0));
        Date now = new Date();
        o.setCTime(now);
        o.setUTime(now);
        sysOrganPrimarydbRepository.insertSysOrgan(o);
        return BaseResultEntity.success(organId);
    }
}
