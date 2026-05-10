package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.vo.*;

public interface SysConfigService {

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
