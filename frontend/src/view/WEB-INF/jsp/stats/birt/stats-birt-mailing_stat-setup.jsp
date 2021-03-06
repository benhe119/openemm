<%@ page language="java" contentType="text/html; charset=utf-8" buffer="32kb" errorPage="/error.do" %>
<%@ page import="com.agnitas.emm.core.workflow.web.ComWorkflowAction" %>
<%@ page import="org.agnitas.web.MailingBaseAction" %>
<%@ taglib uri="http://struts.apache.org/tags-bean" prefix="bean" %>
<%@ taglib uri="http://struts.apache.org/tags-html" prefix="html" %>
<%@ taglib uri="http://struts.apache.org/tags-logic" prefix="logic" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="emm" uri="https://emm.agnitas.de/jsp/jsp/common" %>

<%--@elvariable id="mailingBIRTStatForm" type="com.agnitas.reporting.birt.web.forms.ComMailingBIRTStatForm"--%>
<%--@elvariable id="birtStatForm" type="com.agnitas.web.forms.ComBirtStatForm"--%>
<%--@elvariable id="limitedRecipientOverview" type="java.lang.Boolean"--%>

<c:set var="BASE_ACTION_LIST" 					value="<%= MailingBaseAction.ACTION_LIST %>"						scope="request" />
<c:set var="BASE_ACTION_VIEW" 					value="<%= MailingBaseAction.ACTION_VIEW %>"						scope="request" />
<c:set var="BASE_ACTION_CONFIRM_DELETE" 		value="<%= MailingBaseAction.ACTION_CONFIRM_DELETE %>" 				scope="request" />
<c:set var="BASE_ACTION_CLONE_AS_MAILING" 		value="<%= MailingBaseAction.ACTION_CLONE_AS_MAILING %>"			scope="request" />
<c:set var="WORKFLOW_ID" 						value="<%= ComWorkflowAction.WORKFLOW_ID %>" 						scope="request" />
<c:set var="WORKFLOW_FORWARD_PARAMS" 			value="<%= ComWorkflowAction.WORKFLOW_FORWARD_PARAMS %>"			scope="request" />
<c:set var="WORKFLOW_FORWARD_TARGET_ITEM_ID" 	value="<%= ComWorkflowAction.WORKFLOW_FORWARD_TARGET_ITEM_ID %>"	scope="request" />

<emm:CheckLogon/>
<emm:Permission token="stats.mailing"/>

<c:set var="agnTitleKey" 			value="Mailing" 				scope="request" />
<c:set var="agnSubtitleKey" 		value="Mailing" 				scope="request" />
<c:set var="sidemenu_active" 		value="Statistics" 				scope="request" />
<c:set var="sidemenu_sub_active" 	value="MailStat" 				scope="request" />
<c:set var="agnHighlightKey" 		value="Statistics" 				scope="request" />
<c:set var="isBreadcrumbsShown" 	value="true" 					scope="request" />
<c:set var="agnBreadcrumbsRootKey" 	value="Mailings" 				scope="request" />
<c:set var="agnBreadcrumbsRootUrl" 	value="${mailingsOverviewLink}" scope="request" />

<c:set var="agnSubtitleValue" scope="request">
    <i class="icon icon-envelope"></i>&nbsp;${birtStatForm.shortname}
</c:set>

<c:choose>
    <c:when test="${mailingBIRTStatForm.isMailingGrid}">
        <c:set var="isTabsMenuShown" 	value="false" 																								scope="request" />

        <emm:include page="/WEB-INF/jsp/mailing/fragments/mailing-grid-navigation.jsp"/>

        <emm:instantiate var="agnNavHrefParams" type="java.util.LinkedHashMap" scope="request">
            <c:set target="${agnNavHrefParams}" property="templateID" value="${mailingBIRTStatForm.templateId}"/>
            <c:set target="${agnNavHrefParams}" property="mailingID" value="${mailingBIRTStatForm.mailingID}"/>
        </emm:instantiate>
    </c:when>
    <c:otherwise>
        <c:choose>
            <c:when test="${limitedRecipientOverview}">
                <c:set var="agnNavigationKey" 		value="mailingView_DisabledMailinglist"     scope="request" />
            </c:when>
            <c:otherwise>
                <c:set var="agnNavigationKey" 		value="mailingView"                         scope="request" />
            </c:otherwise>
        </c:choose>
        <c:set var="agnNavHrefAppend" value="&mailingID=${mailingBIRTStatForm.mailingID}&init=true" scope="request" />
    </c:otherwise>
</c:choose>

<emm:instantiate var="reportNameToHelpKeyMap" type="java.util.HashMap">
    <c:set target="${reportNameToHelpKeyMap}" property="mailing_summary.rptdesign" value="summary"/>
    <c:set target="${reportNameToHelpKeyMap}" property="mailing_linkclicks.rptdesign" value="clickstatistic_per_link"/>
    <c:set target="${reportNameToHelpKeyMap}" property="mailing_delivery_progress.rptdesign" value="deliveryProgressStatistic"/>
    <c:set target="${reportNameToHelpKeyMap}" property="mailing_net_and_gross_openings_progress.rptdesign" value="Progress_of_openings"/>
    <c:set target="${reportNameToHelpKeyMap}" property="mailing_linkclicks_progress.rptdesign" value="Progress_of_clicks"/>
    <c:set target="${reportNameToHelpKeyMap}" property="top_domains.rptdesign" value="top_domains"/>
    <c:set target="${reportNameToHelpKeyMap}" property="mailing_bounces.rptdesign" value="bounceStatistic"/>
    <%@ include file="stats-birt-mailing_stat-setup-extended.jspf" %>
</emm:instantiate>

<c:set var="agnHelpKey" value="${reportNameToHelpKeyMap[birtStatForm.reportName]}" scope="request"/>

<c:if test="${empty agnHelpKey}">
    <c:set var="agnHelpKey" value="Statistics" scope="request"/>
</c:if>

<c:url var="mailingsOverviewLink" value="/mailingbase.do">
    <c:param name="action" value="${BASE_ACTION_LIST}"/>
    <c:param name="isTemplate" value="false"/>
    <c:param name="page" value="1"/>
</c:url>

<c:url var="mailingViewLink" value="/mailingbase.do">
    <c:param name="action" value="${BASE_ACTION_VIEW}"/>
    <c:param name="mailingID" value="${mailingBIRTStatForm.mailingID}"/>
    <c:param name="keepForward" value="true"/>
    <c:param name="init" value="true"/>
</c:url>

<emm:instantiate var="agnBreadcrumbs" type="java.util.LinkedHashMap" scope="request">
    <emm:instantiate var="agnBreadcrumb" type="java.util.LinkedHashMap">
        <c:set target="${agnBreadcrumbs}" property="0" value="${agnBreadcrumb}"/>
        <c:set target="${agnBreadcrumb}" property="text" value="${birtStatForm.shortname}"/>
        <c:set target="${agnBreadcrumb}" property="url" value="${mailingViewLink}"/>
    </emm:instantiate>

    <emm:instantiate var="agnBreadcrumb" type="java.util.LinkedHashMap">
        <c:set target="${agnBreadcrumbs}" property="1" value="${agnBreadcrumb}"/>
        <c:set target="${agnBreadcrumb}" property="textKey" value="Statistics"/>
    </emm:instantiate>
</emm:instantiate>

<emm:instantiate var="reports" type="java.util.LinkedHashMap" scope="request">
    <c:set target="${reports}" property="">
    	 <bean:message key="statistic.load.specific"/>
    </c:set>
    <c:set target="${reports}" property="mailing_summary.rptdesign">
        <bean:message key="Summary"/>
    </c:set>
    <c:set target="${reports}" property="mailing_linkclicks.rptdesign">
        <bean:message key="Clickstats_Linkclicks"/>
    </c:set>
    <c:set target="${reports}" property="mailing_delivery_progress.rptdesign">
        <bean:message key="statistic.delivery_progress"/>
    </c:set>
    <c:set target="${reports}" property="mailing_net_and_gross_openings_progress.rptdesign">
        <bean:message key="Clickstats_Openings"/>
    </c:set>
    <c:set target="${reports}" property="mailing_linkclicks_progress.rptdesign">
        <bean:message key="statistic.clicks_progress"/>
    </c:set>
    <c:set target="${reports}" property="top_domains.rptdesign">
    	<bean:message key="statistic.TopDomains"/>
    </c:set>
    <c:set target="${reports}" property="mailing_bounces.rptdesign">
        <bean:message key="statistic.Bounces"/>
    </c:set>
    <%@ include file="stats-birt-mailing_stat-setup-extended2.jspf" %>
</emm:instantiate>

<jsp:include page="/WEB-INF/jsp/mailing/actions-dropdown.jsp">
    <jsp:param name="elementIndex" value="0"/>
    <jsp:param name="mailingId" value="${mailingBIRTStatForm.mailingID}"/>
    <jsp:param name="isTemplate" value="false"/>
    <jsp:param name="workflowId" value="${mailingBIRTStatForm.workflowId}"/>
    <jsp:param name="isMailingUndoAvailable" value="${mailingBIRTStatForm.isMailingUndoAvailable}"/>
</jsp:include>
