from rest_framework import serializers
from .models import Payment
from billing.models import Invoice


class PaymentSerializer(serializers.ModelSerializer):
    invoice_code = serializers.CharField(source='invoice.invoice_id', read_only=True)
    customer_name = serializers.CharField(source='invoice.customer.name', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'payment_id', 'invoice', 'invoice_code',
            'customer_name', 'amount', 'payment_method',
            'payment_status', 'transaction_ref', 'qr_payload',
            'is_demo', 'paid_at', 'notes', 'created_at'
        ]
        read_only_fields = [
            'id', 'payment_id', 'transaction_ref', 'qr_payload',
            'is_demo', 'paid_at', 'created_at'
        ]


class InitiatePaymentSerializer(serializers.Serializer):
    invoice_id = serializers.CharField(required=True)
    payment_method = serializers.ChoiceField(
        choices=Payment.PaymentMethod.choices,
        default=Payment.PaymentMethod.UPI
    )

    def validate_invoice_id(self, value):
        val = value.strip()
        # Find by pk or invoice_id
        inv = Invoice.objects.filter(models_Q(pk=val) if val.isdigit() else models_Q(invoice_id__iexact=val)).first()
        if not inv:
            raise serializers.ValidationError("Invoice not found.")
        if inv.payment_status == Invoice.PaymentStatus.PAID:
            raise serializers.ValidationError("This invoice has already been paid.")
        return inv


def models_Q(**kwargs):
    from django.db.models import Q
    return Q(**kwargs)
