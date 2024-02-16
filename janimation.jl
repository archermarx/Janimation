using GLMakie
set_theme!(theme_light())

function circle_pos(time, period, radius)
    x = radius * cos(2π * time / period)
    y = radius * sin(2π * time / period)
    return Point2f(x, y)
end

names = ["sun", "mercury", "venus", "earth", "mars", "jupter", "saturn", "uranus", "neptune"]
colors = [:yellow, :grey, :orange, :darkturquoise, :red, :lightsalmon, :burlywood3, :aquamarine, RGBf(0.0, 0.3, 0.95)]
sizes = [50, 20, 25, 25, 20, 35, 30, 25, 25]

radius_offset = 0.4
radius_scale = 0.9
radii_planets = radius_offset .+ radius_scale .* (1:8)
radii = [0; radii_planets]
periods = factorial(8) .// [1, 8, 7, 6, 5, 4, 3, 2, 1]
linewidth = 3

bodies = [
   (;name, color, size, radius, period)
   for (name, color, size, radius, period) in zip(names, colors, sizes, radii, periods)
]

size = (1200, 600)
f = Figure(;size)
axis_size = 1.5 * maximum(radii)
lims = (-axis_size, axis_size)
ax_helio = Axis(f[1,1], limits = (lims, lims), aspect = 1)
ax_geo = Axis(f[1,2], limits = (lims, lims), aspect = 1)

hidedecorations!(ax_helio)
hidespines!(ax_helio)
hidedecorations!(ax_geo)
hidespines!(ax_geo)

anim_framerate = 30
anim_num_loops = 2
anim_length_seconds = 15 * anim_num_loops
anim_frames = anim_framerate * anim_length_seconds
t0 = 0.0
tN = anim_num_loops * maximum(periods)
ts = LinRange(t0, tN, anim_frames)

function earth_distance(i, positions, bodies)
    earth_ind = findfirst(x -> x.name == "earth", bodies)
    diff = positions[i][] - positions[earth_ind][]
    return diff
end

positions = [Observable(circle_pos(t0, b.period, b.radius)) for b in bodies]
positions_geo = [Observable(earth_distance(i, positions, bodies)) for i in eachindex(bodies)]
orbits = [Observable(Point2f[]) for b in bodies]
orbits_geo = [Observable(Point2f[]) for i in eachindex(bodies)]

for (i, b) in enumerate(bodies)
    lines!(ax_helio, orbits[i]; color = b.color, linewidth)
    lines!(ax_geo, orbits_geo[i]; color = b.color, linewidth)
    scatter!(ax_helio, positions[i], color = b.color, markersize = b.size)
    scatter!(ax_geo, positions_geo[i], color = b.color, markersize = b.size)
end

record(f, "janimation.mp4", enumerate(ts); framerate = anim_framerate) do (i, t)
    clear = i == (anim_frames ÷ anim_num_loops)
    for (i, b) in enumerate(bodies)
        new_pos = circle_pos(t, b.period, b.radius)
        positions[i][] = new_pos
        if (clear)
             orbits[i][] = Point2f[]
        end
        push!(orbits[i][], new_pos)
        notify(positions[i])
        notify(orbits[i])
    end
    for (i, b) in enumerate(bodies)
        new_pos_geo = earth_distance(i, positions, bodies)
        positions_geo[i][] = new_pos_geo
        if (clear)
            orbits_geo[i][] = Point2f[]
        end
        push!(orbits_geo[i][], new_pos_geo)
        notify(orbits_geo[i])
        notify(positions_geo[i])
    end
end
