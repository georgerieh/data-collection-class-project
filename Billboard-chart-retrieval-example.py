import billboard
import pandas
l = []
chart = billboard.ChartData('hot-100', date='2024-01-07')
for i, val in enumerate(chart):
     l.append({'num': i, 'title':val.title, 'artist':val.artist, 'date':'202\
4-01-07'})
stor = pandas.DataFrame(l)
stor.to_csv('billboard-chart-example.csv')