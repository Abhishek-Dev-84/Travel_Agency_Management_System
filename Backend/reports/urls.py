from django.urls import path
from .views import DashboardSummaryView, ReportsAnalyticsView, ExportCsvView

urlpatterns = [
    path('dashboard/', DashboardSummaryView.as_view(), name='api-dashboard'),
    path('reports/analytics/', ReportsAnalyticsView.as_view(), name='api-reports-analytics'),
    path('reports/export-csv/', ExportCsvView.as_view(), name='api-reports-export-csv'),
]
