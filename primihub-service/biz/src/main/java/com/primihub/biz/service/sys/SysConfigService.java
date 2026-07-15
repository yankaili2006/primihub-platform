package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.vo.*;

import java.util.Map;

public interface SysConfigService {

    // 项目流程审核配置(审核流程节点 + 通知配置, 存为 JSON blob)
    BaseResultEntity getApprovalFlowConfig();
    BaseResultEntity saveApprovalFlowConfig(Map<String, Object> data);


    BaseResultEntity getNetworkConfig();
    BaseResultEntity saveNetworkConfig(NetworkConfigVO vo);

    BaseResultEntity getTimeConfig();
    BaseResultEntity saveTimeConfig(TimeConfigVO vo);

    BaseResultEntity getLoginRestriction();
    BaseResultEntity saveLoginRestriction(LoginRestrictionVO vo);

    BaseResultEntity getPersonalizationConfig();
    BaseResultEntity savePersonalizationConfig(PersonalizationConfigVO vo);

    BaseResultEntity getFtpConfig();
    BaseResultEntity saveFtpConfig(FtpConfigVO vo);
    BaseResultEntity testFtpConnection(FtpConfigVO vo);
}
