package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataProductDemand;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 数据产品需求Repository接口
 */
public interface DataProductDemandPrimarydbRepository {

    /**
     * 插入数据产品需求
     */
    int insertDataProductDemand(DataProductDemand demand);

    /**
     * 更新数据产品需求
     */
    int updateDataProductDemand(DataProductDemand demand);

    /**
     * 删除数据产品需求
     */
    int deleteDataProductDemand(@Param("id") Long id);

    /**
     * 根据ID查询数据产品需求
     */
    DataProductDemand selectDataProductDemandById(@Param("id") Long id);

    /**
     * 查询数据产品需求列表
     */
    List<DataProductDemand> selectDataProductDemandList(Map<String, Object> params);

    /**
     * 查询数据产品需求总数
     */
    int selectDataProductDemandCount(Map<String, Object> params);

    /**
     * 批量插入
     */
    int batchInsertDataProductDemand(@Param("list") List<DataProductDemand> list);
}
