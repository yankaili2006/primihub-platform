package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.DataModelArtifact;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface DataModelArtifactRepository {

    DataModelArtifact queryModelArtifactById(Long artifactId);

    List<DataModelArtifact> queryModelArtifactList(Map<String, Object> paramMap);

    Integer queryModelArtifactCount(Map<String, Object> paramMap);
}
