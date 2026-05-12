package com.primihub.application.controller;

import com.primihub.application.controller.test.TestController;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;

class TestControllerUnitTest {

    @InjectMocks
    private TestController testController;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testHealthConnection() {
        BaseResultEntity result = testController.healthConnection();
        assertEquals(0, result.getCode());
        assertNotNull(result.getResult());
        assertTrue((Long) result.getResult() > 0);
    }
}
