package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.param.FindWhiteListPageParam;
import com.primihub.biz.entity.sys.param.SaveOrUpdateWhiteListParam;
import com.primihub.biz.entity.sys.po.SysWhiteList;
import com.primihub.biz.repository.primarydb.sys.SysWhiteListPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysWhiteListSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class SysWhiteListService {

    @Autowired
    private SysWhiteListPrimarydbRepository sysWhiteListPrimarydbRepository;
    @Autowired
    private SysWhiteListSecondarydbRepository sysWhiteListSecondarydbRepository;

    /**
     * 分页查询白名单列表
     */
    public BaseResultEntity findWhiteListPage(FindWhiteListPageParam param) {
        if (param.getPageNum() == null || param.getPageNum() < 1) {
            param.setPageNum(1);
        }
        if (param.getPageSize() == null || param.getPageSize() < 1) {
            param.setPageSize(10);
        }
        List<SysWhiteList> list = sysWhiteListSecondarydbRepository.selectWhiteListPage(param);
        Integer total = sysWhiteListSecondarydbRepository.selectWhiteListCount(param);
        int pageCount = (int) Math.ceil((double) total / param.getPageSize());

        Map<String, Object> result = new HashMap<>();
        result.put("whiteList", list);
        result.put("total", total);
        result.put("pageNum", param.getPageNum());
        result.put("pageSize", param.getPageSize());
        result.put("pageCount", pageCount);
        return BaseResultEntity.success(result);
    }

    /**
     * 新增白名单
     */
    public BaseResultEntity saveWhiteList(SaveOrUpdateWhiteListParam param) {
        if (param.getWlType() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "wlType");
        }
        if (param.getWlValue() == null || "".equals(param.getWlValue().trim())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "wlValue");
        }

        // 检查是否已存在
        SysWhiteList exist = sysWhiteListSecondarydbRepository.selectWhiteListByValue(param.getWlValue().trim());
        if (exist != null) {
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "该白名单值已存在");
        }

        SysWhiteList whiteList = new SysWhiteList();
        BeanUtils.copyProperties(param, whiteList);
        whiteList.setWlValue(param.getWlValue().trim());
        if (param.getStatus() == null) {
            whiteList.setStatus(1);
        }
        sysWhiteListPrimarydbRepository.insertWhiteList(whiteList);
        return BaseResultEntity.success();
    }

    /**
     * 更新白名单
     */
    public BaseResultEntity updateWhiteList(SaveOrUpdateWhiteListParam param) {
        if (param.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        }
        SysWhiteList whiteList = new SysWhiteList();
        BeanUtils.copyProperties(param, whiteList);
        if (param.getWlValue() != null) {
            whiteList.setWlValue(param.getWlValue().trim());
        }
        sysWhiteListPrimarydbRepository.updateWhiteList(whiteList);
        return BaseResultEntity.success();
    }

    /**
     * 删除白名单
     */
    public BaseResultEntity deleteWhiteList(Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        }
        sysWhiteListPrimarydbRepository.deleteWhiteList(id);
        return BaseResultEntity.success();
    }

    /**
     * 批量删除白名单
     */
    public BaseResultEntity batchDeleteWhiteList(List<Long> idList) {
        if (idList == null || idList.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "idList");
        }
        sysWhiteListPrimarydbRepository.batchDeleteWhiteList(idList);
        return BaseResultEntity.success();
    }

    /**
     * 获取白名单详情
     */
    public BaseResultEntity getWhiteListDetail(Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        }
        SysWhiteList whiteList = sysWhiteListSecondarydbRepository.selectWhiteListById(id);
        if (whiteList == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_NOT_EXIST);
        }
        return BaseResultEntity.success(whiteList);
    }
}