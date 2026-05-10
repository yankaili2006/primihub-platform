package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.SceneApiConfig;
import com.primihub.biz.entity.data.po.SceneKeyConfig;
import com.primihub.biz.entity.data.po.SceneTask;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface ScenePrimarydbRepository {

    // ========== 场景任务 ==========

    void insertSceneTask(SceneTask task);

    void updateSceneTask(SceneTask task);

    SceneTask selectSceneTaskById(@Param("id") Long id);

    List<SceneTask> selectSceneTaskList(Map<String, Object> params);

    int selectSceneTaskCount(Map<String, Object> params);

    // ========== 场景API配置 ==========

    void insertSceneApiConfig(SceneApiConfig config);

    void updateSceneApiConfig(SceneApiConfig config);

    void deleteSceneApiConfig(@Param("id") Long id);

    SceneApiConfig selectSceneApiConfigById(@Param("id") Long id);

    List<SceneApiConfig> selectSceneApiConfigList(@Param("sceneType") String sceneType);

    // ========== 场景密钥配置 ==========

    void insertSceneKeyConfig(SceneKeyConfig config);

    void updateSceneKeyConfig(SceneKeyConfig config);

    void deleteSceneKeyConfig(@Param("id") Long id);

    SceneKeyConfig selectSceneKeyConfigById(@Param("id") Long id);

    List<SceneKeyConfig> selectSceneKeyConfigList(@Param("sceneType") String sceneType);
}
