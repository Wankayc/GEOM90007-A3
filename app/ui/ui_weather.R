# Trip tab UI

trip_tab_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h2("Trip-Weather Planner"),
    fluidRow(
      column(
        width = 4, class = "d-flex justify-content-center",  
        div(class = "card p-3",
            airDatepickerInput(
              inputId = ns("range"),
              label = NULL,
              value = NULL,
              minDate = as.Date("2024-09-01"),
              maxDate = as.Date("2025-10-31"),
              range = TRUE, inline = TRUE, autoClose = TRUE,
              width = "100%"
            )
        )
      ),
      column(
        width = 8,
        div(class = "card p-3",
            uiOutput(ns("range_summary"))
        )
      )
    ),
    
    br(),
    
    div(class = "card p-3",
        tags$small(class="text-muted d-block mb-2","Drag options into each date box"),
        fluidRow(
          column(6, h5("Outdoor activities"), uiOutput(ns("outdoor_list"))),
          column(6, h5("Indoor activities"),  uiOutput(ns("indoor_list")))
        )
    ),
    
    div(class = "card p-3",
        h4("Activity Planner"),
        uiOutput(ns("itinerary_boards"))
    ),
    
    tags$style(HTML("
      /* cards: minimal design */
      .card { border:1px solid #e5e7eb; border-radius:14px; box-shadow:none; }
      
      .cal-card{
        display:inline-block;
        padding:12px 14px;
      }
      .cal-card .air-datepicker{ margin:0 auto; }
    
      /* datepicker size adjustments */
      .air-datepicker-global-container, .air-datepicker { font-size:16px; }
      .air-datepicker--content { padding:14px 16px; }
      .air-datepicker-cell.-day- { height:44px; position:relative; }
      .air-datepicker-cell.-disabled- { color:#9aa3ad!important; background:#f3f5f7!important; cursor:not-allowed!important; opacity:.7; }
    
      /* itinerary board layout */
      .itinerary-row {
        display:flex; gap:16px; flex-wrap:nowrap;
        overflow-x:auto; padding-bottom:6px;
      }
      .board-col { flex:1 0 14%; min-width:220px; }
      .board-col h6 { margin:0 0 .4rem 0; font-weight:700; color:#111827; }
      .board-col .rank-list.dropzone {
        min-height:92px; border:1px dashed #d1d5db;
        border-radius:12px; background:#fafafa;
      }
    
      /* drag lists (pool/board) styled as chips */
      .rank-list.chips.pool {
        min-height:84px; border:1px dashed #d1d5db;
        border-radius:12px; padding:8px; background:#fff;
      }
      .rank-list.chips.board {
        min-height:92px; border:1px dashed #d1d5db;
        border-radius:12px; padding:8px; background:#fafafa;
      }
      .rank-list .rank-list-item {
        padding:6px 10px; border-radius:9999px;
        border:1px solid #e5e7eb; background:#fff; font-weight:600;
      }
    
      /* chip bar for daily weather summary */
      .metrics-row {
        display:flex; gap:8px; flex-wrap:wrap;
        margin:.25rem 0 .5rem 0;
      }
      .chip {
        display:inline-flex; align-items:center; gap:6px;
        padding:6px 10px; border:1px solid #e5e7eb;
        border-radius:9999px; background:#fff;
      }
      .chip .ico { font-size:1.05rem; line-height:1; }
      .chip .val { font-weight:700; font-size:.95rem; color:#111827; }
      .chip .sub { font-size:.75rem; color:#6b7280; }
      .chip.muted { background:#f8fafc; border-color:#e5e7eb; }
    
      /* simple, compact tables */
      .table-clean.table-sm>tbody>tr>td,
      .table-clean>thead>tr>th {
        padding: .25rem .6rem;   /* tighter cell padding */
        vertical-align: middle;  /* center vertically */
      }
      .table-clean {
        border-collapse: separate;
        border-spacing: 0;
      }
      .text-right { text-align: right; }
             
      /* compact data table tweaks */
      .table-clean th,
      .table-clean td { vertical-align: middle; }
      
      .col-num { text-align: right; white-space: nowrap; }
      .col-left { text-align: left;  }
      
      .wx-cell { display:flex; align-items:center; gap:.4rem; }
      .wx-ico  { font-size:1.05rem; line-height:1; }
      
      .temp-cell .mean { font-weight:800; }
      .temp-cell .min  { color:#2563eb; font-weight:600; }  // blue
      .temp-cell .max  { color:#ef4444; font-weight:600; }  // red
      
      .pm-badge{ display:inline-flex; align-items:center; gap:.35rem; }
      
      /* activity chips — keep the original look */
      .rank-list.chips.pool .rank-list-item{
        display:inline-block;
        margin:6px 8px 0 0; padding:8px 12px;
        background:#eaf7f0;
        color:#0f5132; border:1px solid #b7e4c7;
        border-radius:999px; font-weight:600;
        box-shadow:0 2px 6px rgba(16,185,129,.10);
        cursor:grab; user-select:none;
      }
      .rank-list.chips.board .rank-list-item{
        display:inline-block;
        margin:6px 8px 0 0; padding:8px 12px;
        background:#f1edff;
        color:#3b3070; border:1px solid #d6ccff;
        border-radius:999px; font-weight:600;
        box-shadow:0 2px 6px rgba(99,102,241,.12);
        cursor:grabbing; user-select:none;
      }
      
      /* stacked chip: value on top, small caption below */
      .chip.stack{
        display:inline-flex; flex-direction:column; align-items:flex-start;
        gap:2px; padding:6px 10px; border:1px solid #e5e7eb;
        border-radius:9999px; background:#fff;
      }
      .chip.stack .row1{display:flex; align-items:center; gap:6px; line-height:1}
      .chip .ico{font-size:1.05rem; line-height:1}
      .chip .val{font-weight:700; font-size:.95rem; color:#111827}
      .chip .unit{font-size:.8rem; color:#6b7280}
      .chip .cap{
        display:block; font-size:.70rem; color:#94a3b8;
        text-transform:uppercase; letter-spacing:.04em; font-weight:700;
      }
      
      .wx-ico { font-size:1.05rem; line-height:1; margin-right:.15rem; }
      
      /* summary row cards */
      .summary-list{ display:flex; flex-direction:column; gap:10px; }
      .row-card{
        display:flex; align-items:center; gap:12px; padding:10px 12px;
        background:#fff; border:1px solid #e5e7eb; border-radius:14px;
      }
      .row-card .date{ width:140px; font-weight:700; }
      .row-card .wx{ display:flex; align-items:center; gap:6px; width:110px; color:#334155; }
      .row-card .chips{ display:flex; flex-wrap:wrap; gap:8px; }

    ")),
    
    tags$style(HTML("
      .summary-list .row-card { padding:14px 16px; } 
      .summary-list .date { font-size:1.0rem; }
      .summary-list .wx { font-size:1.15rem; }
      .summary-list .wx span:first-child { font-size:1.35rem; line-height:1; }
    
      .summary-metrics .chip { padding:8px 12px; } 
      .summary-metrics .chip .ico  { font-size:1.20rem; } 
      .summary-metrics .chip .val  { font-size:0.90rem; font-weight:700; } 
      .summary-metrics .chip .unit { font-size:.70rem; }        
      .summary-metrics .chip .cap  { font-size:.60rem; }      
    ")),
    
    tags$script(HTML("
      (function(){
        function decorate(map){
          if(!map) return;
          const cells = document.querySelectorAll('.air-datepicker .air-datepicker-cell.-day-');
          cells.forEach(function(cell){
            const d = cell.getAttribute('data-date');
            cell.classList.remove('wd-sunny','wd-cloudy','wd-rainy');
            for (let i=0;i<map.length;i++){
              if (map[i].date === d) { cell.classList.add(map[i].class); break; }
            }
          });
        }
        window.__wdMap = [];
        Shiny.addCustomMessageHandler('decorateCalendar', function(map){
          window.__wdMap = map || []; decorate(window.__wdMap);
        });
        const obs = new MutationObserver(function(){ decorate(window.__wdMap); });
        obs.observe(document.body, {subtree:true, childList:true});
      })();
    ")),
    
    tags$script(HTML("
    (function(){
      function esc(id){ return '#'+id.replace(/([:\\.\\[\\],])/g, '\\\\$1'); }
  
       function getInstanceFromNode(node){
        if (!node) return null;
        var $n = $(node);
        return (
          $n.data('datepicker')    ||
          $n.data('airDatepicker') ||
          $n.data('adp')           ||
          node._airDatepicker      ||
          node.adp                 ||
          node.datepicker          ||
          null
        );
      }
  
      function findNode(id){
        var el = document.querySelector(esc(id));
        if (el) return el;
        var air = document.querySelector(esc(id + '-air'));
        if (air) return air;
        var el2 = document.querySelector(esc(id) + ' + .air-datepicker');
        if (el2) return el2;
        var parent = document.querySelector(esc(id))?.parentElement;
        if (parent){
          var any = parent.querySelector('.air-datepicker');
          if (any) return any;
        }
        return null;
      }
  
      function setViewById(id, y, m){
        var node = findNode(id);
        if (!node) return false;
  
        var dp = getInstanceFromNode(node) || getInstanceFromNode($(node).prev()[0]);
        if (!dp){
          var nodeAir = findNode(id + '-air');
          dp = getInstanceFromNode(nodeAir);
        }
        if (!dp) return false;
  
        var d = new Date(y, (m||1)-1, 1);
  
        if (typeof dp.setViewDate === 'function'){ dp.setViewDate(d); return true; }
        if ('viewDate' in dp && typeof dp.update === 'function'){ dp.viewDate = d; dp.update(); return true; }
        if (typeof dp.selectDate === 'function'){
          var curValue = (node.tagName === 'INPUT') ? node.value : undefined;
          dp.selectDate(d, { silent: true });
          if (curValue !== undefined) node.value = curValue;
          return true;
        }
        return false;
      }
  
      Shiny.addCustomMessageHandler('airdp-set-view', function(p){
        var ok = setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month);
        if (ok) return;
        setTimeout(function(){ setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month); }, 50);
        setTimeout(function(){ setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month); }, 150);
      });
    })();
  ")),
    
    
    tags$script(HTML("
  (function(){
    //debug
    //console.log('Activity planner loaded');
    
    function valuesOf($list){
      return $list.find('.rank-list-item')
                  .map(function(){ return $(this).text().trim(); })
                  .get();
    }
    
    function hasOutdoor(vals){
      var outdoorEmoji = /^[🍖🥾🧺🧗🏊️]/;
      return vals.some(function(v){ return outdoorEmoji.test(v); });
    }
        
    function pushState($list){
      if (!$list || $list.length === 0) return;
      var domId = $list.attr('id');
      if (!domId) return;
      
      var shinyId = domId.replace(/^rank-list-/, '');
      
      window._pushTimers = window._pushTimers || {};
      if (window._pushTimers[shinyId]) clearTimeout(window._pushTimers[shinyId]);
      
      // read after all changes have been settled
      
      window._pushTimers[shinyId] = setTimeout(function(){ 
      //requestAnimationFrame(function(){
        var vals = valuesOf($list);
        var hasOut = hasOutdoor(vals);
      
        //console.log('pushState:', id, '| Count:', vals.length);
        
        // send status to Shiny
        Shiny.setInputValue(shinyId, vals.length > 0 ? vals : null, {priority:'event'});
        Shiny.setInputValue(shinyId + '_length', vals.length, {priority:'event'});
        Shiny.setInputValue(shinyId + '_has_outdoor', hasOut, {priority:'event'});
        Shiny.setInputValue(shinyId + '_changed', Math.random(), {priority:'event'});
        
        if (!hasOut) {
          Shiny.setInputValue(shinyId + '_outdoor_gone', Math.random(), {priority:'event'});
        }
      
        // if zero activity, remove it
        //var adviceId = id.replace('rank-list-trip-board_', 'trip-advice_');
        var adviceId = shinyId.replace('board_', 'advice_');
        var el = document.getElementById(adviceId);
        if (el && (!hasOut || vals.length === 0)) el.innerHTML = '';
        
        
        delete window._pushTimers[shinyId];
      }, 30);
    }
    
    function ensureRemoveButtons(){
      document.querySelectorAll('.rank-list.chips.board .rank-list-item').forEach(function(item){
        if (!item.querySelector('.chip-remove')) {
          var b = document.createElement('span');
          b.className = 'chip-remove';
          item.appendChild(b);
        }
      });
    }
    
    ensureRemoveButtons();
    const obsButtons = new MutationObserver(function(){ ensureRemoveButtons(); });
    obsButtons.observe(document.body, {subtree:true, childList:true});
    
    const obs = new MutationObserver(function(muts){
      muts.forEach(function(m){
        if (m.type === 'childList') {
          var list = m.target.closest('.rank-list.chips.board');
          if (list && list.id) {
              setTimeout(function(){ pushState($(list)); }, 0); 
              //pushState($list);
          }
        }
      });
    });
    
    obs.observe(document.body, {subtree:true, childList:true});

  })();
  ")),
    
    tags$style(HTML("
    .rank-list.chips.board .rank-list-item{ cursor:pointer; }
    .rank-list .rank-list-item { position: relative; }
    .rank-list .chip-remove{
      position:absolute; top:-6px; right:-6px;
      width:18px; height:18px; border-radius:50%;
      border:1px solid #e5e7eb; background:#fff;
      font-size:12px; line-height:16px; text-align:center;
      cursor:pointer; box-shadow:0 1px 3px rgba(0,0,0,.08);
    }
    .rank-list .chip-remove::after { content:'×'; }

  "))
    
  )
}

# At bottom of ui_weather.R
weather_tab_ui <- function() {
  page_fillable(
    theme = bs_theme(version = 5, primary = "#1f334a"),
    trip_tab_ui("trip")
  )
}
