package com.primihub.biz.repository.secondarydb.sys;

import com.primihub.biz.entity.sys.param.FindWhiteListPageParam;
import com.primihub.biz.entity.sys.po.SysWhiteList;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SysWhiteListSecondarydbRepository {
    List<SysWhiteList> selectWhiteListPage(FindWhiteListPageParam param);
    Integer selectWhiteListCount(FindWhiteListPageParam param);
    SysWhiteList selectWhiteListById(Long id);
    SysWhiteList selectWhiteListByValue(String wlValue);
    List<SysWhiteList> selectWhiteListByType(Integer wlType);
}