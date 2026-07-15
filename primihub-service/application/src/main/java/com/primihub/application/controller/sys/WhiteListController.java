package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.FindWhiteListPageParam;
import com.primihub.biz.entity.sys.param.SaveOrUpdateWhiteListParam;
import com.primihub.biz.service.sys.SysWhiteListService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 白名单管理 Controller
 */
@RequestMapping("whiteList")
@RestController
public class WhiteListController {

    @Autowired
    private SysWhiteListService sysWhiteListService;

    /**
     * 分页查询白名单列表
     */
    @RequestMapping("findWhiteListPage")
    public BaseResultEntity findWhiteListPage(FindWhiteListPageParam param) {
        return sysWhiteListService.findWhiteListPage(param);
    }

    /**
     * 新增白名单
     */
    @RequestMapping("saveWhiteList")
    public BaseResultEntity saveWhiteList(SaveOrUpdateWhiteListParam param,
                                           @RequestHeader(value = "userId", defaultValue = "-1") Long userId,
                                           @RequestHeader(value = "userName", defaultValue = "") String userName) {
        if (param.getWlValue() == null || "".equals(param.getWlValue().trim())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "wlValue");
        }
        if (param.getWlType() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "wlType");
        }
        param.setCreatorId(userId > 0 ? userId : null);
        param.setCreatorName(userName);
        return sysWhiteListService.saveWhiteList(param);
    }

    /**
     * 更新白名单
     */
    @RequestMapping("updateWhiteList")
    public BaseResultEntity updateWhiteList(SaveOrUpdateWhiteListParam param) {
        if (param.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        }
        return sysWhiteListService.updateWhiteList(param);
    }

    /**
     * 删除白名单
     */
    @RequestMapping("deleteWhiteList")
    public BaseResultEntity deleteWhiteList(Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        }
        return sysWhiteListService.deleteWhiteList(id);
    }

    /**
     * 批量删除白名单
     */
    @RequestMapping("batchDeleteWhiteList")
    public BaseResultEntity batchDeleteWhiteList(List<Long> idList) {
        if (idList == null || idList.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "idList");
        }
        return sysWhiteListService.batchDeleteWhiteList(idList);
    }

    /**
     * 获取白名单详情
     */
    @RequestMapping("getWhiteListDetail")
    public BaseResultEntity getWhiteListDetail(Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        }
        return sysWhiteListService.getWhiteListDetail(id);
    }
}