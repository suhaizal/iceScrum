%{--
- Copyright (c) 2010 iceScrum Technologies.
-
- This file is part of iceScrum.
-
- iceScrum is free software: you can redistribute it and/or modify
- it under the terms of the GNU Affero General Public License as published by
- the Free Software Foundation, either version 3 of the License.
-
- iceScrum is distributed in the hope that it will be useful,
- but WITHOUT ANY WARRANTY; without even the implied warranty of
- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
- GNU General Public License for more details.
-
- You should have received a copy of the GNU Affero General Public License
- along with iceScrum.  If not, see <http://www.gnu.org/licenses/>.
-
- Authors:
-
- Vincent Barrier (vbarrier@kagilum.com)
- Manuarii Stein (manuarii.stein@icescrum.com)
--}%

<%@ page import="grails.converters.JSON; org.icescrum.core.domain.Task;org.icescrum.core.domain.Sprint;org.icescrum.core.domain.Story;" %>

<g:set var="poOrSm" value="${request.productOwner || request.scrumMaster}"/>
<is:kanban id="kanban-sprint-${sprint.id}"
           class="${sprint.state == Sprint.STATE_DONE ? 'done' : ''}"
           elemid="${sprint.id}"
           selectable="[filter:'div.postit-rect',
                        cancel:'span.postit-label, div.postit-story, a, span.mini-value, select, input',
                        selected:'jQuery.icescrum.dblclickSelectable(ui,300,function(obj){'+is.quickLook(params:'\'task.id=\'+jQuery.icescrum.postit.id(obj.selected)')+';})']"
           droppable='[selector:".kanban tbody tr",
                       hoverClass: "active",
                       rendered:(poOrSm && sprint.state != Sprint.STATE_DONE),
                       drop: remoteFunction(controller:"story",
                                           action:"plan",
                                           onSuccess:"ui.draggable.attr(\"remove\",\"true\"); jQuery.event.trigger(\"plan_story\",data.story)",
                                           params:"\"&product=${params.product}&id=\"+ui.draggable.attr(\"elemid\")+\"&position=\"+(jQuery(\"table.kanban tbody tr.row-story\").index(this) == -1 ? jQuery(\"table.kanban tbody tr.row-story\").index(this) + 2 : jQuery(\"table.kanban tbody tr.row-story\").index(this) + 1 )+\"&sprint.id=\"+jQuery(\"table.kanban\").attr(\"elemid\")"
                                           ),
                       accept: ".postit-row-story"]'>
%{-- Columns' headers --}%
    <is:kanbanHeader name="Story" key="story"/>
    <g:each in="${columns}" var="column">
        <is:kanbanHeader name="${message(code:column.name)}" key="${column.key}"/>
    </g:each>

%{-- Recurrent Tasks --}%
    <is:kanbanRow rendered="${displayRecurrentTasks}" class="row-recurrent-task" type="${Task.TYPE_RECURRENT}">

        <is:kanbanColumn>
            <g:message code="is.ui.sprintPlan.kanban.recurrentTasks"/>
            <g:if test="${request.inProduct && sprint.state <= Sprint.STATE_INPROGRESS}">
                <is:menu yoffset="3" class="dropmenu-action" id="menu-recurrent"
                         contentView="window/recurrentOrUrgentTask"
                         params="[sprint:sprint,previousSprintExist:previousSprintExist,type:'recurrent']"
                         rendered="${sprint.state != Sprint.STATE_DONE}"/>
            </g:if>
        </is:kanbanColumn>

        <g:each in="${columns}" var="column" status="i">
            <is:kanbanColumn key="${column.key}">
                <g:each in="${recurrentTasks?.sort{it.rank}?.findAll{ it.state == column.key} }" var="task">
                    <is:cache cache="taskCache" key="postit-${task.id}-${task.lastUpdated}">
                        <g:include view="/task/_postit.gsp" model="[task:task,user:user]"
                                   params="[product:params.product]"/>
                    </is:cache>
                </g:each>

            </is:kanbanColumn>
        </g:each>

    </is:kanbanRow>

%{-- Urgent Tasks --}%
    <is:kanbanRow rendered="${displayUrgentTasks}" class="row-urgent-task" type="${Task.TYPE_URGENT}">
        <is:kanbanColumn>
            <g:message code="is.ui.sprintPlan.kanban.urgentTasks"/>
            <g:if test="${request.inProduct && sprint.state <= Sprint.STATE_INPROGRESS}">
                <is:menu yoffset="3"
                         class="dropmenu-action"
                         id="menu-urgent"
                         contentView="window/recurrentOrUrgentTask"
                         params="[sprint:sprint,type:'urgent']"
                         rendered="${sprint.state != Sprint.STATE_DONE}"/>
            </g:if>
            <br/>
            <span id='limit-urgent-tasks' style='display:${limitValueUrgentTasks > 0 ? 'block' : 'none'}'>${message(code: 'is.ui.sprintPlan.kanban.urgentTasks.limit', args:[limitValueUrgentTasks])}</span>
        </is:kanbanColumn>
        <g:each in="${columns}" var="column">
            <is:kanbanColumn key="${column.key}">
                <g:each in="${urgentTasks?.sort{it.rank}?.findAll{it.state == column.key}}" var="task">
                    <is:cache  cache="taskCache" key="postit-${task.id}-${task.lastUpdated}">
                        <g:include view="/task/_postit.gsp" model="[task:task,user:user]" params="[product:params.product]"/>
                    </is:cache>
                </g:each>

            </is:kanbanColumn>
        </g:each>
    </is:kanbanRow>

%{-- Stories Rows --}%
    <is:kanbanRows in="${stories.sort{it.rank}}"
                   var="story"
                   class="row-story"
                   elemid="id"
                   type="story"
                   emptyRendering="true">
            <is:kanbanColumn elementId="column-story-${story.id}">
                <is:cache  cache="storyCache" key="postit-${story.id}-${story.lastUpdated}">
                    <g:include view="/story/_postit.gsp"
                               model="[story:story,user:user,sprint:sprint,nextSprintExist:nextSprintExist,referrer:sprint.id]"
                               params="[product:params.product]"/>
                </is:cache>
            </is:kanbanColumn>

        %{-- Workflow Columns --}%
            <g:each in="${columns}" var="column">
                <is:kanbanColumn key="${column.key}">
                    <g:each in="${story.tasks?.sort{it.rank}?.findAll{ (hideDoneState) ? (it.state == column.key && it.state != Task.STATE_DONE) : (it.state == column.key) }}"
                            var="task">
                                <g:include view="/task/_postit.gsp" model="[task:task,user:user]" params="[product:params.product]"/>
                    </g:each>
                </is:kanbanColumn>
            </g:each>
    </is:kanbanRows>

    <is:kanbanRows in="${storiesDone.sort{it.rank}}"
                   var="story"
                   class="row-story"
                   elemid="id"
                   data-state="state"
                   type="storyDone"
                   emptyRendering="true">
        <is:kanbanColumn elementId="column-story-${story.id}">
            <is:cache  cache="storyCache" key="postit-${story.id}-${story.lastUpdated}">
                <g:include view="/story/_postit.gsp"
                           model="[story:story,user:user,sprint:sprint,nextSprintExist:nextSprintExist,referrer:sprint.id]"
                           params="[product:params.product]"/>
            </is:cache>
        </is:kanbanColumn>

    %{-- Workflow Columns --}%
        <g:each in="${columns}" var="column">
            <is:kanbanColumn key="${column.key}">
                <g:each in="${story.tasks?.sort{it.rank}?.findAll{ (hideDoneState) ? (it.state == column.key && it.state != Task.STATE_DONE) : (it.state == column.key) }}"
                        var="task">
                    <g:include view="/task/_postit.gsp" model="[task:task,user:user]" params="[product:params.product]"/>
                </g:each>
            </is:kanbanColumn>
        </g:each>
    </is:kanbanRows>

</is:kanban>

<jq:jquery>
    jQuery('table#kanban-sprint-${sprint.id} div.postit-story').die('dblclick').live('dblclick',function(e){ var obj = jQuery(e.currentTarget);${is.quickLook(params: '\'story.id=\'+obj.attr(\"elemId\")')}});
    jQuery.icescrum.sprint.updateWindowTitle(${[id:sprint.id,orderNumber:sprint.orderNumber,totalRemainingHours:sprint.totalRemainingHours,state:sprint.state,startDate:sprint.startDate,endDate:sprint.endDate] as JSON});
    <g:if test="${assignOnBeginTask && !request.scrumMaster && sprint.state != Sprint.STATE_DONE}">
        jQuery.icescrum.sprint.sortableTasks();
    </g:if>
    <is:editable rendered="${sprint.state != Sprint.STATE_DONE && (request.teamMember || request.scrumMaster)}"
                 controller="story"
                 action='estimate'
                 on='table.kanban div.postit-story span.mini-value.editable'
                 findId="jQuery(this).parents('.postit-story:first').attr('elemid')"
                 type="selectui"
                 name="story.effort"
                 before="jQuery(this).next().hide();"
                 cancel="jQuery(original).next().show();"
                 values="${suiteSelect}"
                 ajaxoptions = "{dataType:'json'}"
                 callback="jQuery(this).html(value.effort);jQuery(this).next().show();"
                 params="[product:params.product]"/>

    <is:editable rendered="${sprint.state != Sprint.STATE_DONE}"
                 on="div.postit-task span.mini-value.editable"
                 typed="[type:'numeric',allow:'?.,']"
                 onExit="submit"
                 action="estimate"
                 controller="task"
                 highlight="true"
                 before="jQuery(this).next().hide();"
                 cancel="jQuery(original).next().show();"
                 ajaxoptions = "{dataType:'json'}"
                 callback="jQuery(this).next().show(); jQuery(this).html(jQuery.icescrum.formattedTaskEstimation(value.estimation)); jQuery.icescrum.sprint.updateRemaining(); if(value.state == ${Task.STATE_DONE}){ jQuery.event.trigger('update_task',value); }"
                 params="[product:params.product]"
                 findId="jQuery(this).parents('.postit-task:first').attr('elemid')"/>

    <is:sortable rendered="${sprint.state != Sprint.STATE_DONE}"
                 on="table.kanban td.kanban-col:not(:first-child)"
                 handle="p.postit-sortable"
                 containment="#window-content-sprintPlan table"
                 cancel=".ui-selectable-disabled"
                 connectWith="td.kanban-cell"
                 items="div.postit-rect"
                 revert="true"
                 live="true"
                 over="jQuery.icescrum.sprint.droppableTasks(this, ui)"
                 update="var container = jQuery(this).find('.postit-rect'); if(container.index(ui.item) != -1 && ui.sender == undefined){${is.changeRank(controller:'task',action:'rank',name:'task.rank',params:'&product='+params.product+'')}}"
                 placeholder="postit-placeholder ui-corner-all"
                 receive="${remoteFunction(controller:'task',
                                   action:'state',
                                   onFailure:'jQuery(ui.sender).sortable(\'cancel\');',
                                   onSuccess:'data.story ? jQuery.event.trigger(\'update_story\',data.story) : jQuery.event.trigger(\'update_task\',data.task);',
                                   params:'\'state=\'+jQuery(this).attr(\'type\')+\'&product='+params.product+'&id=\'+ui.item.attr(\'elemid\')+\'&position=\'+(jQuery(this).find(\'.postit-rect\').index(ui.item)+1)+ (jQuery(this).parent().attr(\'type\') ? \'&task.type=\'+jQuery(this).parent().attr(\'type\') : \'\') + (jQuery(this).parent().attr(\'elemid\') ? \'&story.id=\'+jQuery(this).parent().attr(\'elemid\') : \'\')',
                                   before:'if(jQuery(ui.placeholder).hasClass(\'no-drop\')){jQuery(ui.sender).sortable(\'cancel\'); return;}')}"/>
</jq:jquery>
<is:shortcut key="space"
             callback="if(jQuery('#dialog').dialog('isOpen') == true){jQuery('#dialog').dialog('close'); return false;}jQuery.icescrum.dblclickSelectable(null,null,function(obj){${is.quickLook(params:'\'task.id=\'+jQuery.icescrum.postit.id(obj.selected)')}},true);"
             scope="${controllerName}"/>
<is:shortcut key="ctrl+a" callback="jQuery('#window-content-${controllerName} .ui-selectee').addClass('ui-selected');"/>

<is:onStream
        on="#kanban-sprint-${sprint.id}"
        events="[[object:'story',events:['update','estimate','unPlan','plan','done','unDone','inProgress','associated','dissociated']]]"
        template="sprintPlan"/>

<is:onStream
        on="#kanban-sprint-${sprint.id}"
        events="[[object:'task',events:['add','update','remove']]]"
        template="sprintPlan"/>

<is:onStream
        on="#kanban-sprint-${sprint.id}"
        events="[[object:'sprint',events:['close','activate']]]"/>

<is:onStream
        on="#kanban-sprint-${sprint.id}"
        events="[[object:'feature',events:['update']]]"/>