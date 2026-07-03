package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.SharedDataset;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 共享数据集 Repository（真实 DB 持久化，替换原 mock 内存实现）
 */
public interface SharedDatasetPrimarydbRepository {

    int insertSharedDataset(SharedDataset sharedDataset);

    int updateSharedDataset(SharedDataset sharedDataset);

    int deleteSharedDataset(@Param("id") Long id);

    int batchDeleteSharedDataset(@Param("ids") List<Long> ids);

    int updateSharedDatasetStatus(@Param("id") Long id, @Param("shareStatus") Integer shareStatus);

    SharedDataset selectSharedDatasetById(@Param("id") Long id);

    SharedDataset selectSharedDatasetByCode(@Param("datasetCode") String datasetCode);

    List<SharedDataset> selectSharedDatasetList(Map<String, Object> params);

    int selectSharedDatasetCount(Map<String, Object> params);

    List<Map<String, Object>> selectShareableResources(@Param("organId") Long organId);
}
