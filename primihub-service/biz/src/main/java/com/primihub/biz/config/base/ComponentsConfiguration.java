package com.primihub.biz.config.base;

import com.primihub.biz.entity.data.vo.ModelComponent;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.List;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "components")
public class ComponentsConfiguration {
    private List<ModelComponent> modelComponents;
}
