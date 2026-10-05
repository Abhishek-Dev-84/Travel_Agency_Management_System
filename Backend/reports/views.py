from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
import csv
from django.http import HttpResponse

from vehicles.models import Vehicle
from drivers.models import Driver
from bookings.models import Booking, Customer
from duty_slips.models import DutySlip
from billing.models import Invoice
from maintenance.models import WorkOrder


class DashboardSummaryView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        today = timezone.now().date()
        week_ago = today - timedelta(days=6)

        # Vehicles
        total_vehicles = Vehicle.objects.count()
        available_vehicles = Vehicle.objects.filter(status=Vehicle.Status.AVAILABLE).count()
        on_trip_vehicles = Vehicle.objects.filter(status=Vehicle.Status.ON_TRIP).count()
        maintenance_vehicles = Vehicle.objects.filter(status=Vehicle.Status.MAINTENANCE).count()

        # Drivers
        total_drivers = Driver.objects.count()
        available_drivers = Driver.objects.filter(status=Driver.Status.AVAILABLE).count()
        on_duty_drivers = Driver.objects.filter(status=Driver.Status.ON_DUTY).count()
        lic_alerts = Driver.objects.filter(license_expiry__lte=today + timedelta(days=30)).count()

        # Bookings
        total_bookings = Booking.objects.count()
        pending_bookings = Booking.objects.filter(status=Booking.Status.PENDING).count()
        confirmed_bookings = Booking.objects.filter(status=Booking.Status.CONFIRMED).count()
        completed_bookings = Booking.objects.filter(status=Booking.Status.COMPLETED).count()
        cancelled_bookings = Booking.objects.filter(status=Booking.Status.CANCELLED).count()

        # Financials
        paid_inv = Invoice.objects.filter(payment_status=Invoice.PaymentStatus.PAID)
        unpaid_inv = Invoice.objects.filter(payment_status=Invoice.PaymentStatus.UNPAID)
        total_revenue = float(paid_inv.aggregate(s=Sum('grand_total'))['s'] or 0)
        pending_revenue = float(unpaid_inv.aggregate(s=Sum('grand_total'))['s'] or 0)
        total_invoices = Invoice.objects.count()
        paid_invoices = paid_inv.count()

        # 7-day bookings breakdown
        day_names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        day_counts = [0] * 7
        recent_week_bookings = Booking.objects.filter(pickup_date__gte=week_ago, pickup_date__lte=today)
        for b in recent_week_bookings:
            idx = b.pickup_date.weekday()
            # python weekday: 0=Mon, 6=Sun; map to Sun=0 .. Sat=6
            mapped_idx = (idx + 1) % 7
            day_counts[mapped_idx] += 1

        # Recent bookings
        recent_bookings = []
        for b in Booking.objects.select_related('customer', 'vehicle').order_by('-created_at')[:8]:
            recent_bookings.append({
                'id': b.booking_id,
                'customer': b.customer.name,
                'phone': b.customer.phone,
                'vehicle': b.vehicle.make_model,
                'pickup_date': str(b.pickup_date),
                'return_date': str(b.return_date),
                'status': b.status,
                'fare': float(b.base_fare)
            })

        # Recent activities based on actual events
        activities = []
        for b in Booking.objects.select_related('customer').order_by('-created_at')[:3]:
            activities.append({
                'type': 'booking',
                'color': 'green' if b.status == 'Confirmed' else 'orange',
                'icon': '✓' if b.status == 'Confirmed' else '◷',
                'title': f"Booking #{b.booking_id} ({b.status})",
                'desc': f"For {b.customer.name} - {b.pickup_location} → {b.destination_location}",
                'time': b.created_at.strftime("%d %b %H:%M")
            })

        for w in WorkOrder.objects.select_related('vehicle').order_by('-created_at')[:2]:
            activities.append({
                'type': 'maintenance',
                'color': 'red',
                'icon': '⚙',
                'title': f"Maintenance for {w.vehicle.make_model}",
                'desc': f"{w.service_type} ({w.status})",
                'time': w.created_at.strftime("%d %b %H:%M")
            })

        return Response({
            'vehicles': {
                'total': total_vehicles,
                'available': available_vehicles,
                'on_trip': on_trip_vehicles,
                'maintenance': maintenance_vehicles
            },
            'drivers': {
                'total': total_drivers,
                'available': available_drivers,
                'on_duty': on_duty_drivers,
                'license_alerts': lic_alerts
            },
            'bookings': {
                'total': total_bookings,
                'pending': pending_bookings,
                'confirmed': confirmed_bookings,
                'completed': completed_bookings,
                'cancelled': cancelled_bookings,
                'weekly_counts': day_counts,
                'day_labels': day_names
            },
            'revenue': {
                'total_revenue': total_revenue,
                'pending_revenue': pending_revenue,
                'total_invoices': total_invoices,
                'paid_invoices': paid_invoices
            },
            'recent_bookings': recent_bookings,
            'recent_activities': activities
        })


class ReportsAnalyticsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        today = timezone.now().date()

        # Monthly performance for last 6 months
        months = []
        for i in range(5, -1, -1):
            # calculate year and month
            year = today.year
            month = today.month - i
            while month <= 0:
                month += 12
                year -= 1

            m_bookings = Booking.objects.filter(pickup_date__year=year, pickup_date__month=month)
            m_invoices = Invoice.objects.filter(issue_date__year=year, issue_date__month=month, payment_status=Invoice.PaymentStatus.PAID)

            b_count = m_bookings.count()
            rev = float(m_invoices.aggregate(s=Sum('grand_total'))['s'] or 0)
            avg = round(rev / b_count, 2) if b_count > 0 else 0

            month_name = timezone.datetime(year, month, 1).strftime("%b %Y")
            months.append({
                'month': month_name,
                'bookings': b_count,
                'revenue': rev,
                'avg': avg,
                'utilization': min(100, int((b_count / max(1, Vehicle.objects.count() * 30)) * 100)),
                'growth': 0
            })

        # Calculate month-over-month growth
        for i in range(1, len(months)):
            prev = months[i - 1]['revenue']
            curr = months[i]['revenue']
            if prev > 0:
                months[i]['growth'] = round(((curr - prev) / prev) * 100, 1)

        # Bookings by type
        type_counts = {
            'Sedan': Booking.objects.filter(vehicle__vehicle_type='Sedan').count(),
            'SUV': Booking.objects.filter(vehicle__vehicle_type='SUV').count(),
            'Hatchback': Booking.objects.filter(vehicle__vehicle_type='Hatchback').count(),
            'Van': Booking.objects.filter(vehicle__vehicle_type='Van').count()
        }

        # Top drivers
        top_drivers = []
        for d in Driver.objects.all():
            completed_slips = DutySlip.objects.filter(driver=d, status=DutySlip.Status.COMPLETED)
            trip_count = completed_slips.count()
            earned = float(completed_slips.aggregate(s=Sum('payout'))['s'] or 0)
            top_drivers.append({
                'name': d.name,
                'trips': trip_count,
                'rating': float(d.rating),
                'revenue': earned
            })
        top_drivers.sort(key=lambda x: x['trips'], reverse=True)
        top_drivers = top_drivers[:4]

        # Top vehicles
        top_vehicles = []
        for v in Vehicle.objects.all():
            v_bookings = Booking.objects.filter(vehicle=v)
            trip_count = v_bookings.count()
            v_rev = float(Invoice.objects.filter(vehicle=v, payment_status=Invoice.PaymentStatus.PAID).aggregate(s=Sum('grand_total'))['s'] or 0)
            top_vehicles.append({
                'name': v.make_model,
                'trips': trip_count,
                'revenue': v_rev
            })
        top_vehicles.sort(key=lambda x: x['revenue'], reverse=True)
        top_vehicles = top_vehicles[:4]

        # Overall KPIs
        total_rev = float(Invoice.objects.filter(payment_status=Invoice.PaymentStatus.PAID).aggregate(s=Sum('grand_total'))['s'] or 0)
        total_bk = Booking.objects.count()
        active_customers = Customer.objects.filter(bookings__isnull=False).distinct().count()
        avg_driver_rating = round(float(Driver.objects.all().aggregate(r=models_Avg('rating'))['r'] or 5.0), 1) if Driver.objects.exists() else 0.0

        return Response({
            'kpis': {
                'total_revenue': total_rev,
                'total_bookings': total_bk,
                'active_customers': active_customers,
                'avg_rating': avg_driver_rating
            },
            'monthly_performance': months,
            'booking_types': type_counts,
            'top_drivers': top_drivers,
            'top_vehicles': top_vehicles
        })


def models_Avg(field):
    from django.db.models import Avg
    return Avg(field)


class ExportCsvView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        data_type = request.query_params.get('type', 'bookings')
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="tams_{data_type}_report.csv"'
        writer = csv.writer(response)

        if data_type == 'invoices':
            writer.writerow(['Invoice ID', 'Booking ID', 'Customer', 'Vehicle', 'Issue Date', 'Base Fare', 'Tax', 'Grand Total', 'Status', 'Method'])
            for inv in Invoice.objects.select_related('customer', 'vehicle', 'booking').all():
                writer.writerow([
                    inv.invoice_id,
                    inv.booking.booking_id if inv.booking else '—',
                    inv.customer.name,
                    inv.vehicle.make_model,
                    inv.issue_date,
                    inv.base_fare,
                    inv.tax_amount,
                    inv.grand_total,
                    inv.payment_status,
                    inv.payment_method
                ])
        else:
            writer.writerow(['Booking ID', 'Customer', 'Phone', 'Vehicle', 'Pickup', 'Destination', 'Pickup Date', 'Return Date', 'Fare', 'Status'])
            for b in Booking.objects.select_related('customer', 'vehicle').all():
                writer.writerow([
                    b.booking_id,
                    b.customer.name,
                    b.customer.phone,
                    b.vehicle.make_model,
                    b.pickup_location,
                    b.destination_location,
                    b.pickup_date,
                    b.return_date,
                    b.base_fare,
                    b.status
                ])

        return response
