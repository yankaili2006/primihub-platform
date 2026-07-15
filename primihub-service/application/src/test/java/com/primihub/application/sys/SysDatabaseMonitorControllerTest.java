package com.primihub.application.sys;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.restdocs.AutoConfigureRestDocs;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.restdocs.mockmvc.MockMvcRestDocumentation.document;
import static org.springframework.restdocs.operation.preprocess.Preprocessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@AutoConfigureMockMvc @AutoConfigureRestDocs(outputDir = "target/generated-snippets")
@RunWith(SpringRunner.class) @SpringBootTest
public class SysDatabaseMonitorControllerTest {
    @Autowired private MockMvc mockMvc;
    @Test public void testGetList() throws Exception { mockMvc.perform(get("/databaseMonitor/getList")).andExpect(status().isOk()).andExpect(jsonPath("$.code").value(0)).andDo(document("getDatabaseMonitorList", preprocessRequest(prettyPrint()), preprocessResponse(prettyPrint()))); }
    @Test public void testSaveMissingType() throws Exception { mockMvc.perform(post("/databaseMonitor/save")).andExpect(status().isOk()).andExpect(jsonPath("$.code").value(1)); }
    @Test public void testDeleteMissingId() throws Exception { mockMvc.perform(get("/databaseMonitor/delete")).andExpect(status().isOk()).andExpect(jsonPath("$.code").value(1)); }
}