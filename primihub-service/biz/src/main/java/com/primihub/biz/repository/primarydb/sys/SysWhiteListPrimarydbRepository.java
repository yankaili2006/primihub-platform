package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.SysWhiteList;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SysWhiteListPrimarydbRepository {
    void insertWhiteList(SysWhiteList whiteList);
    void updateWhiteList(SysWhiteList whiteList);
    void deleteWhiteList(@Param("id") Long id);
    void batchDeleteWhiteList(@Param("idList") List<Long> idList);
}