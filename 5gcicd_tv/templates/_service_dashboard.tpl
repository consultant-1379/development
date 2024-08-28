{{- define "service_dashboard" -}}
    <% num_col = 0 %>
    <% Builds::FLOW_LIST.each_with_index do |flow, index_f| %>
    <% if flow['id'] == {{ . | upper | quote }} then %>
        <% num_col = flow['builds'].count %>
    <% end %>
    <% end %>
    <% app_col = num_col - 2 %>
    <% row_label_size = 5 %>
    <% col_label_size = 3 %>
    <% row_gap_size = 1 %>

    <% app_label_size = 1 %>
    <% stage_label_size = 2 %>
    <% col_label_size =  app_label_size + stage_label_size %>

    <% criteria_row_size = 1 %>
    <% total_x = (num_col + 1) * 3 + row_gap_size +  row_label_size%>
    <script type='text/javascript'>
    $(function() {
    Dashing.numColumns = <%= (num_col + 1) * 3 + row_label_size + row_gap_size %>;
    Dashing.widget_margins = [1, 3];
    Dashing.widget_base_dimensions = [45, 35]
    });
    </script>
    </script>
    <style type="text/css">
    body {
      font-size: 10px;
    }
    h1 {
      font-size: 10px;
      margin-bottom: 3px;
      margin-top: 3px;
    }

    h2 {
      font-size: 14px;
    }

    h3 {
      font-size: 22px;
      margin-bottom: 2px;
      margin-top: 2px;
    }

    li {
      font-size: 10px;
    }

    .updated-at {
      font-size: 17px;
      bottom: 1px;
    }

    .more-info {
      font-size: 8px;
      bottom: 10px;
    }
    .widget {
      vertical-align: top;
      padding: 1px 2px;
    }
    </style>
    <% content_for :title do %>{{ . | upper }} Dashboard<% end %>
    <center><div style="font-size: 72px"> {{ . | upper }} Pipeline </div></center>
    <br>
    <center><div style="font-size: 24px; color:red"> Software listed on this page is pre-PRA drops, not released </div></center>
    <div class="gridster">
      <ul>
      <li data-row="<%= app_label_size + 1%>"
        data-col="1"
        data-sizex="<%= row_label_size %>" data-sizey="<%= stage_label_size %>">
        <div data-id="service" onclick="location.href='adp_dashboard';" data-text="&#8678" style="background-color: #3385ff; "
          data-view="Text"></div>
      </li>
  <li data-row="<%= app_label_size + 1%>"
    data-col="<%= row_label_size + 1 %>"
    data-sizex="3" data-sizey="<%= stage_label_size %>">
    <div data-id="service" data-text="Own CI" style="background-color: #3385ff"
      data-view="Text"></div>
  </li>
  <li data-row="<%= app_label_size + 1%>"
    data-col="<%= row_label_size + 4 %>"
    data-sizex="3" data-sizey="<%= stage_label_size %>">
    <div data-id="service" data-text="ADP Staging" style="background-color: #3385ff"
      data-view="Text"></div>
  </li>
  <li data-row="1"
    data-col="<%= row_label_size + 7 %>"
    data-sizex="<%= app_col * 3 %>" data-sizey="<%= app_label_size %>">
    <div data-id="service" data-text="Application Staging" style="background-color: #3385ff"
      data-view="Text"></div>
  </li>
  <% Builds::FLOW_LIST[0]['builds'].each_with_index do |build, index| %>
    <% if index > 1 then %>
      <li data-row="<%= app_label_size + 1%>"
        data-col="<%= row_label_size + 7 + (index - 2) * 3 %>"
        data-sizex="3" data-sizey="<%= stage_label_size %>">
        <div data-id="service" data-text="<%= build['pretty-name'] %>"" style="background-color: #3385ff"
          data-view="Text"></div>
      </li>
    <%end %>
  <%end %>
  <li data-row="1"
    data-col="<%= (num_col) * 3 + row_label_size + row_gap_size + 1%>"
    data-sizex="3" data-sizey="<%= col_label_size %>">
    <div data-id="service" data-text="Latest Successful RC" style="background-color: #3385ff"
      data-view="Text"></div>
  </li>
    <% offset = 0 %>
    <% Builds::FLOW_LIST.each_with_index do |flow, index_f| %>
    <% if flow['id'] == {{ . | upper | quote }} then %>
    <% flow_num = 2 + (3 * offset) + col_label_size - 1%>
    <% offset = offset + (flow['builds'].count - 3) / app_col %>
      <li data-row="<%= flow_num %>"
        data-col="1"
        data-sizex="<%= row_label_size %>" data-sizey="<%= ((flow['builds'].count - 3) / app_col + 1) * 3 %>">
        <div data-id="service" data-text="<%= flow['id'] %>" style="background-color: #3385ff;"
          data-view="Text"></div>
      </li>
          <% flow['builds'].each_with_index do |build, index| %>
      <% if index > 1 then 
            build_num = 2 + (index - 2) % app_col
            y_pos = (index - 2) / app_col
         else
            build_num = index
            y_pos = 0
         end
      %>
      <% x_pos = 2 + (build_num * 3) %>
      <li data-row="<%= flow_num + 3 * y_pos %>"
        data-col="<%= x_pos %>"
        data-sizex="3" data-sizey="3">
        <div data-id="<%= build['id'] %>" data-server="<%= build['server'] %>"
          data-view="BuildWindow"></div>
      </li>
    <% end %>
      <li data-row="<%= flow_num %>"
        data-col="<%= (num_col) * 3 + row_label_size + row_gap_size + 1%>"
        data-sizex="3"
        data-sizey="3">
        <div data-id="<%= flow['lastStable']['id'] %>" data-server="Jenkins"
          data-view="BuildWindow"></div>
      </li>
      <% end %>
        <% end %>
      <% row_offset = 4 + 3 * offset + col_label_size%>
      <li data-row="<%= row_offset %>"
        data-col="1"
        data-sizex="<%= total_x / 2  %>" data-sizey="1">
        <div data-id="info" data-title="CI/CD Criteria Conformance" style="background-color: #3385ff"
          data-view="Text"></div>
      </li>
      <li data-row="<%= row_offset %>"
        data-col="<%= total_x / 2 + 1  %>"
        data-sizex="<%= total_x / 2 + total_x % 2 %>" data-sizey="1">
        <div data-id="info" data-title="Open Issues" style="background-color: #3385ff"
          data-view="Text"></div>
      </li>
      <li data-row="<%= row_offset + 1 %>"
        data-col="<%= total_x / 2 + 1  %>"
        data-sizex="<%= total_x / 2 + total_x % 2 %>" data-sizey="<%= Builds::CRITERIA_LIST.count * criteria_row_size%>">
        <div data-id="info" style="background-color: #999999"
          data-view="List"></div>
      </li>
       <% Builds::CRITERIA_LIST.each_with_index do |criteria, index_c| %>
       <li data-row="<%= row_offset + 1 + criteria_row_size * index_c %>"
        data-col="1"
        data-sizex="<%= total_x/2 - 1 %>" data-sizey="<%= criteria_row_size %>">
        <div data-id="<%= criteria['id'] + "-{{ . | upper }}" %>" data-title="<%= criteria['text'] %>" 
          data-view="Health"></div>
       </li>
       <li data-row="<%= row_offset + 1 + criteria_row_size * index_c %>"
        data-col="<%= total_x/2 %>"
        data-sizex="1" data-sizey="<%= criteria_row_size %>">
        <div data-id="<%= criteria['id'] + "-{{ . | upper }}" %>"  data-icon="1"
          data-view="Health"></div>
       </li>
       <% end %>
      </ul>
    </div>
{{- end -}}
