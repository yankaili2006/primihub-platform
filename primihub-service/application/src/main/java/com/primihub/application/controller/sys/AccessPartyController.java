package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveAccessPartyParam;
import com.primihub.biz.service.sys.SysAccessPartyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("accessParty")
@RestController
public class AccessPartyController {
    @Autowired private SysAccessPartyService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("save") public BaseResultEntity save(SaveAccessPartyParam param) {
        if (param.getPartyName()==null||"".equals(param.getPartyName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"partyName");
        return service.save(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}