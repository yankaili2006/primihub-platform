package com.primihub.biz.entity.base;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class BaseResultEntityTest {

    @Test
    void testSuccess() {
        BaseResultEntity result = BaseResultEntity.success();
        assertEquals(0, result.getCode().intValue());
        assertEquals("请求成功", result.getMsg());
    }

    @Test
    void testSuccessWithData() {
        BaseResultEntity result = BaseResultEntity.success("test_data");
        assertEquals(0, result.getCode().intValue());
        assertEquals("test_data", result.getResult());
    }

    @Test
    void testFailure() {
        BaseResultEntity result = BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL);
        assertEquals(1002, result.getCode().intValue());
    }

    @Test
    void testFailureWithMessage() {
        BaseResultEntity result = BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "userId");
        assertNotNull(result.getMsg());
    }

    @Test
    void testBaseResultEnumValues() {
        assertNotNull(BaseResultEnum.SUCCESS);
        assertEquals(0, BaseResultEnum.SUCCESS.getReturnCode().intValue());
        assertEquals("请求成功", BaseResultEnum.SUCCESS.getMessage());
    }

    @Test
    void testSettersAndGetters() {
        BaseResultEntity entity = new BaseResultEntity();
        entity.setCode(999);
        entity.setMsg("custom");
        entity.setResult("data");

        assertEquals(999, entity.getCode().intValue());
        assertEquals("custom", entity.getMsg());
        assertEquals("data", entity.getResult());
    }
}
