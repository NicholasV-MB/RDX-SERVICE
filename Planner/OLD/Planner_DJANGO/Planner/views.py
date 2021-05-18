from django.http import HttpResponse, JsonResponse
from datetime import datetime, timedelta
from Planner.utils import *
from Planner.c_utils import find_best_monthly_planner
from django.middleware.csrf import get_token
from django.views.decorators.csrf import csrf_exempt
import json

@csrf_exempt
def find_planner(request):
    """
    Method for evaluate best planner and render result
    @param: request
    """
    context = {}
    if request.method == 'POST':
        json_data = json.loads(request.body)
        context["year"] = json_data.get("year")
        monthinteger = int(json_data.get("month"))
        month = datetime(1900, monthinteger, 1).strftime('%B')
        context["month"] = month
        events_min = []
        errors = []
        tot_ev_duration = 0
        events = json_data.get("events")
        for ev in events:
            print(ev)
            location = ev.get("address")
            lat, long = get_lat_long_from_location(location)
            # print(lat, long)
            if (lat==None or long==None):
                errors.append({"message": "Could not find Coordinates for location "+location})
                continue

            duration = float(ev.get("duration"))
            tot_ev_duration += float(duration)
            subject = ev.get("title")
            text = subject + "<br>" + location + "<br>Duration: " + str(duration)+" Hours"
            event_min = {
                "subject": subject,
                "text": text,
                "latitude": lat,
                "longitude": long,
                "duration": duration,
                "location": location,
                "info": ev.get("info")
            }
            events_min.append(event_min)

        context["events"] = events_min
        context["events_info"]= {
            "tot_duration": tot_ev_duration
        }
        context["headquarter"] = {
            "latitude": MB_HEADQUARTER_LATITUDE,
            "longitude": MB_HEADQUARTER_LONGITUDE
        }
        print("find all routes")
        routes, new_errors = get_all_routes(events_min)
        errors.extend(new_errors)
        context["routes"] = routes
        max_days = json_data.get("max_days")
        context["max_days"] = max_days
        planner = find_best_monthly_planner(events_min, routes, max_days, "ModulBlok Headquarter")

        context["planner"] = planner
        context["planner_info"] = get_planner_info(planner)
        context["planner_events"] = {}
        context["planner_rdx"] = []
        for week in planner:
            week_events = []
            rdx_data = {
                "week": week,
                "activities": [],
            }
            for el in planner[week]:
                rdx_data["activities"].append(el)
                if el["type"]=="event":
                    week_events.append(el)
            context["planner_events"][week] = week_events
            context["planner_rdx"].append(rdx_data)

        if len(errors)>0:
            context["errors"] = errors
    else:
        context["errors"] = [{"message": "Method error"}]
    return HttpResponse(json.dumps(context))
