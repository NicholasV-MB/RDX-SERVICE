import requests
import json
import os 
from inspect import getsourcefile
from os.path import abspath

dir_path = os.path.join(
        abspath(getsourcefile(lambda:0)),
        os.pardir
    )
# dir_path = os.path.dirname(os.path.realpath(__file__))

# BASE URLS
nominatim_base_url = "https://nominatim.openstreetmap.org/search"
osrm_base_url = "http://router.project-osrm.org/route/v1/car"

# GLOBAL VAR OF LAT&LONG of ModulBlok Headquarter
MB_HEADQUARTER_LATITUDE = 46.117620
MB_HEADQUARTER_LONGITUDE = 13.194870


def get_lat_long_from_location(address):
    """
    Try to find data in file coordinates.json or
    Request to Nominatim Latitude and Longitude from given address
    @param address: string
    @output Lat, Long: string
    """
    file_name = str(dir_path).replace("\\", "/")+"/coordinates.json"
    with open(file_name, "r+") as f:
        json_data = f.read()
        coordinates = json.loads(json_data)
    if coordinates:
        for js_coord in coordinates:
            if js_coord["address"]==address:
                lat = float(js_coord["latitude"])
                long = float(js_coord["longitude"])
                return lat, long
    r = requests.get('{0}?q={1}&format=jsonv2'.format(nominatim_base_url, address))
    if str(r.status_code)=="200":
        json_resp = r.json()
        json_resp = json_resp[0] if len(json_resp)>0 else {}
        lat = json_resp.get("lat", None)
        long = json_resp.get("lon", None)
        if lat != None and long != None:
            data_to_save = {
                "address": address,
                "latitude": lat,
                "longitude": long
            }
            coordinates.append(data_to_save)
            with open(file_name, "w") as f:
                f.write(json.dumps(coordinates))
    else:
        lat = None
        long = None
    return lat, long


def get_all_routes(events_min):
    """
    Method for get every possible route between given events
    @param events_min: list of dicts with event info
    @return routes: lisf of dicts of routes found
    @return errors: list of dicts of error (routes not found)
    """
    errors = []
    routes = []
    remaining_evs = [e for e in events_min ]
    idx_ev = 1
    for ev in events_min:
        idx_ev+=1
        # find all routes between events' locations and start point
        route = get_route(
            MB_HEADQUARTER_LATITUDE,
            MB_HEADQUARTER_LONGITUDE,
            ev["latitude"],
            ev["longitude"]
        )
        if(route!=None):
            f = "ModulBlok Headquarter"
            to = ev["text"].split("<br>")[1]
            route["text"] = "-> "+f+"<br>-> "+to+"<br>"+route["text"]
            route["from"] = f
            route["to"] = to
            routes.append(route)
        else:
            errors.append({
                "message":"Could not find route from ModulBlok Headquarter to latitude:"+str(ev["latitude"])+" longitude:"+str(ev["longitude"])
            })
        remaining_evs.remove(ev)
        for r_ev in remaining_evs:
            route = get_route(
                ev["latitude"],
                ev["longitude"],
                r_ev["latitude"],
                r_ev["longitude"]
            )

            if(route!=None):
                f = ev["text"].split("<br>")[1]
                to = r_ev["text"].split("<br>")[1]
                route["text"] = "-> "+f +"<br>-> "+to+ "<br>"+route["text"]
                route["from"] = f
                route["to"] = to
                routes.append(route)
            else:
                errors.append({
                    "message":"Could not find route from latitude:"+str(ev["latitude"])+" longitude:"+str(ev["longitude"]) +" to latitude:"+str(r_ev["latitude"])+" longitude:"+str(r_ev["longitude"])
                    })

    return routes, errors

def get_route(lat1, long1, lat2, long2):
    """
    Try to find route in data/routes.json or
    Request to OSRM route from given points
    @params lat1, long1: latitude and longitude of start point
    @params lat2, long2: latitude and longitude of end point
    @output route: dict
    """
    file_name = str(dir_path).replace("\\", "/")+"/routes.json"
    with open(file_name, "r+") as f:
        json_data = f.read()
        routes = json.loads(json_data)
    if routes:
        for js_route in routes:
            if (float(js_route["lat1"])==lat1 and float(js_route["long1"])==long1 and \
                float(js_route["lat2"])==lat2 and float(js_route["long2"])==long2) or \
                (float(js_route["lat1"])==lat2 and float(js_route["long1"])==long2 and \
                float(js_route["lat2"])==lat1 and float(js_route["long2"])==long1):
                return js_route["route_info"]

    url = '{0}/{1},{2};{3},{4}?overview=full'.format(
        osrm_base_url,
        long1,
        lat1,
        long2,
        lat2)
    try:
        r = requests.get(url)

        if str(r.status_code)=="200":
            r_json = r.json()
            duration = round(r_json["routes"][0]["duration"]/3600, 2)
            distance = round(r_json["routes"][0]["distance"]/1000, 2)
            text = str(distance) + " KM<br>"+ str(duration)+" Hours"
            geometry = r_json["routes"][0]["geometry"]
            resp = {
                "text": text,
                "geometry": r_json["routes"][0]["geometry"].replace("\\", "\\\\"),
                "duration": duration,
                "distance": distance
            }
            data_to_save = {
                "lat1": lat1,
                "long1": long1,
                "lat2": lat2,
                "long2": long2,
                "route_info": resp
            }
            routes.append(data_to_save)
            with open(file_name, "w") as f:
                f.write(json.dumps(routes))
        else:
            print(url)
            resp = None
    except Exception as e:
        print(e)
        resp = None
    return resp


def get_planner_info(planner):
    """
    Method for getting information about duration of events, trips and total of week activites
    @param planner: dict of activities
    @return planner_info: dict with duration info
    """
    planner_info = {}
    for week in planner:
        tot_duration = sum((el["duration"] for el in planner[week]))
        trip_duration = sum((el["duration"]  for el in planner[week]  if el["type"]=="trip"))
        ev_duration = sum((el["duration"]  for el in planner[week]  if el["type"]=="event" ))
        planner_info[week] = {
            "tot_duration": round(tot_duration, 2),
            "trip_duration": round(trip_duration, 2),
            "ev_duration": round(ev_duration, 2)
        }
    return planner_info